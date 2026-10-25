#import "SMTTouchView.h"
#import <SMTUserDefaults/SMTUserDefaults.h>
#import <SMTTouchSettings/SMTTouchSettings.h>
#import <Private/CALayer+Private.h>

#define kNodeCount 6
#define kMaxTrailPoints 160
#define SMTDistance(a, b) hypot((a).x - (b).x, (a).y - (b).y)

typedef struct {
    CGPoint origin;
    NSInteger columns;
    NSInteger rows;
    CGFloat step;
} SMTGrid;

@implementation SMTTouchView
{
    BOOL _morph;
    BOOL _comet;
    CGFloat _cornerRadius;
    CADisplayLink *_displayLink;

    CGPoint _nodes[kNodeCount];
    CGPoint _restPoint;

    CAShapeLayer *_shapeLayer;
    CGPoint _tailPoints[kNodeCount];
    CGFloat _tailRadii[kNodeCount];
    NSInteger _tailCount;
    CGFloat _headHalfSize;
    CGFloat _headCorner;
    CGFloat _blend;

    CAShapeLayer *_trailLayer;
    CGPoint _trailPoints[kMaxTrailPoints];
    CFTimeInterval _trailTimes[kMaxTrailPoints];
    NSInteger _trailCount;

    BOOL _dismissed;
    BOOL _fadeFinished;
    CFTimeInterval _dismissStart;
    CFTimeInterval _dismissDuration;
    CGFloat _dismissScale;
}

- (instancetype)initWithCenter:(CGPoint)center {
    SMTUserDefaults *defaults = [SMTUserDefaults standardUserDefaults];
    CGFloat size = defaults.touchSize;

    self = [super initWithFrame:CGRectMake(0, 0, size, size)];

    if (self) {
        self.center = center;
        self.userInteractionEnabled = NO;
        self.layer.allowsHitTesting = NO;

        UIImage *image = defaults.imageEnabled ? defaults.touchImage : nil;

        _morph = defaults.morphEnabled && !image;
        _comet = defaults.cometEnabled;
        _cornerRadius = MIN(defaults.touchRadius, size / 2);
        _restPoint = center;

        for (NSInteger i = 0; i < kNodeCount; i++) {
            _nodes[i] = center;
        }

        if (image) {
            [self setupImage:image];
        } else if (_morph) {
            [self setupMorphWithDefaults:defaults];
        } else {
            [self setupPlainWithDefaults:defaults];
        }

        if (_comet) {
            [self setupTrailWithDefaults:defaults masked:!image];
        }

        [self scheduleBreathing];
    }

    return self;
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];

    if (!_trailLayer) {
        return;
    }

    if (self.superview) {
        [self.superview.layer insertSublayer:_trailLayer below:self.layer];
    } else {
        [_trailLayer removeFromSuperlayer];
    }
}

- (void)didMoveToWindow {
    [super didMoveToWindow];

    if (!self.window) {
        [self stopDisplayLink];
    }
}

#pragma mark - Setup

- (void)setupImage:(UIImage *)image {
    self.layer.contents = (id)image.CGImage;
    self.layer.contentsGravity = kCAGravityResizeAspect;
}

- (void)setupPlainWithDefaults:(SMTUserDefaults *)defaults {
    self.backgroundColor = defaults.touchColor;
    self.layer.cornerRadius = _cornerRadius;
    self.layer.borderColor = defaults.borderColor.CGColor;
    self.layer.borderWidth = defaults.borderWidth;
    self.clipsToBounds = CGRectGetWidth(self.bounds) / 2 <= _cornerRadius;
}

- (void)setupMorphWithDefaults:(SMTUserDefaults *)defaults {
    _shapeLayer = [self shapeLayerWithColor:defaults.touchColor];
    _shapeLayer.frame = self.bounds;
    _shapeLayer.fillRule = kCAFillRuleEvenOdd;
    _shapeLayer.strokeColor = defaults.borderColor.CGColor;
    _shapeLayer.lineWidth = defaults.borderWidth;
    _shapeLayer.lineJoin = kCALineJoinRound;
    [self.layer addSublayer:_shapeLayer];

    [self updateShape];
}

- (void)setupTrailWithDefaults:(SMTUserDefaults *)defaults masked:(BOOL)masked {
    _trailLayer = [self shapeLayerWithColor:defaults.touchColor];

    if (masked) {
        CAShapeLayer *mask = [self shapeLayerWithColor:[UIColor blackColor]];
        mask.fillRule = kCAFillRuleEvenOdd;
        _trailLayer.mask = mask;
    }

    [self addTrailPoint:_nodes[0]];
}

- (CAShapeLayer *)shapeLayerWithColor:(UIColor *)color {
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.fillColor = color.CGColor;
    layer.actions = @{@"path": [NSNull null]};
    layer.allowsHitTesting = NO;

    return layer;
}

#pragma mark - Touch lifecycle

- (void)moveToPoint:(CGPoint)point {
    if (SMTDistance(point, _restPoint) > SMTTouchSettings.restTolerance) {
        _restPoint = point;
        [self pauseBreathing];
    }

    _nodes[0] = point;

    if (_comet) {
        [self addTrailPoint:point];
    }

    if (_morph || _comet) {
        [self startDisplayLink];
    } else {
        self.center = point;
    }
}

- (void)dismiss {
    [self cancelScheduledBreathing];
    CGFloat scale = [self stopBreathing];
    _dismissed = YES;

    if (_comet) {
        [self releaseTrail];
        [self startDisplayLink];
    }

    CGFloat duration = [SMTUserDefaults standardUserDefaults].duration;

    if (duration <= 0) {
        self.alpha = 0.0;
        _fadeFinished = YES;
        [self removeIfFinished];
    } else if (_morph) {
        [self beginMorphFadeWithDuration:duration fromScale:scale];
    } else {
        [self fadeOutWithDuration:duration fromScale:scale];
    }
}

- (void)fadeOutWithDuration:(CFTimeInterval)duration fromScale:(CGFloat)scale {
    CGFloat releaseScale = SMTTouchSettings.releaseScale;

    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = @1.0;
    fade.toValue = @0.0;

    CABasicAnimation *grow = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    grow.fromValue = @(scale);
    grow.toValue = @(releaseScale);

    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[fade, grow];
    group.duration = duration;
    group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        self->_fadeFinished = YES;
        [self removeIfFinished];
    }];

    self.layer.opacity = 0.0;
    self.layer.transform = CATransform3DMakeScale(releaseScale, releaseScale, 1.0);
    [self.layer addAnimation:group forKey:@"fadeOut"];

    [CATransaction commit];
}

- (void)beginMorphFadeWithDuration:(CFTimeInterval)duration fromScale:(CGFloat)scale {
    _dismissDuration = duration;
    _dismissScale = scale;
    _dismissStart = CACurrentMediaTime();

    [self startDisplayLink];
}

- (void)stepMorphFade {
    CGFloat progress = MIN((CACurrentMediaTime() - _dismissStart) / _dismissDuration, 1.0);
    CGFloat eased = 1.0 - (1.0 - progress) * (1.0 - progress);
    CGFloat scale = _dismissScale + (SMTTouchSettings.releaseScale - _dismissScale) * eased;

    self.alpha = 1.0 - eased;
    self.transform = CGAffineTransformMakeScale(scale, scale);
    _fadeFinished = progress >= 1.0;
}

- (void)removeIfFinished {
    if (!_fadeFinished || _trailCount > 0) {
        return;
    }

    [self stopDisplayLink];
    [self removeFromSuperview];
}

#pragma mark - Idle breathing

- (void)scheduleBreathing {
    [self cancelScheduledBreathing];
    [self performSelector:@selector(startBreathing) withObject:nil afterDelay:SMTTouchSettings.breathIdleDelay];
}

- (void)cancelScheduledBreathing {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startBreathing) object:nil];
}

- (void)startBreathing {
    CABasicAnimation *breath = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    breath.fromValue = @1.0;
    breath.toValue = @(SMTTouchSettings.breathScale);
    breath.duration = SMTTouchSettings.breathDuration;
    breath.autoreverses = YES;
    breath.repeatCount = HUGE_VALF;
    breath.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    [self.layer addAnimation:breath forKey:@"breath"];
}

- (void)pauseBreathing {
    if ([self.layer animationForKey:@"breath"]) {
        CABasicAnimation *settle = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        settle.fromValue = @([self stopBreathing]);
        settle.toValue = @1.0;
        settle.duration = SMTTouchSettings.breathSettleDuration;
        settle.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

        [self.layer addAnimation:settle forKey:@"breathSettle"];
    }

    [self scheduleBreathing];
}

- (CGFloat)stopBreathing {
    CGFloat scale = [[self.layer.presentationLayer valueForKeyPath:@"transform.scale"] doubleValue] ?: 1.0;

    [self.layer removeAnimationForKey:@"breath"];
    [self.layer removeAnimationForKey:@"breathSettle"];

    return scale;
}

#pragma mark - Frames

- (void)startDisplayLink {
    if (_displayLink) {
        return;
    }

    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(step:)];

    if (@available(iOS 15.0, *)) {
        _displayLink.preferredFrameRateRange = CAFrameRateRangeMake(60, 120, 120);
    }

    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopDisplayLink {
    [_displayLink invalidate];
    _displayLink = nil;
}

- (void)step:(CADisplayLink *)link {
    CGFloat dt = MIN(MAX(link.targetTimestamp - link.timestamp, 1.0 / 240.0), 1.0 / 30.0);
    BOOL settled = YES;

    if (_morph) {
        settled = [self moveTailWithDuration:dt];
    }

    self.center = _nodes[0];

    if (_morph) {
        [self updateShape];
    }

    if (_comet) {
        [self updateTrail];
        settled = settled && _trailCount == 0;
    }

    if (_dismissStart) {
        [self stepMorphFade];
    }

    if (_dismissed) {
        [self removeIfFinished];
    } else if (settled) {
        [self stopDisplayLink];
    }
}

#pragma mark - Morph tail

- (BOOL)moveTailWithDuration:(CGFloat)dt {
    CGFloat size = CGRectGetWidth(self.bounds);
    CGFloat follow = 1.0 - exp(-SMTTouchSettings.followRate * dt);
    CGFloat maxSegment = size * SMTTouchSettings.maxTail / (kNodeCount - 1);
    CGFloat minBendRadius = SMTTouchSettings.minBendRadius;
    BOOL settled = YES;

    for (NSInteger i = 1; i < kNodeCount; i++) {
        CGPoint previous = _nodes[i - 1];
        CGPoint node = _nodes[i];
        node.x += (previous.x - node.x) * follow;
        node.y += (previous.y - node.y) * follow;

        CGFloat dx = node.x - previous.x;
        CGFloat dy = node.y - previous.y;
        CGFloat segment = hypot(dx, dy);

        if (segment > maxSegment) {
            dx *= maxSegment / segment;
            dy *= maxSegment / segment;
            segment = maxSegment;
        }

        if (i >= 2 && segment > 0.01 && SMTDistance(previous, _nodes[i - 2]) > 0.01) {
            CGFloat previousAngle = atan2(previous.y - _nodes[i - 2].y, previous.x - _nodes[i - 2].x);
            CGFloat turn = remainder(atan2(dy, dx) - previousAngle, 2 * M_PI);
            CGFloat maxTurn = MIN(segment / (size * minBendRadius), 0.9);

            if (fabs(turn) > maxTurn) {
                CGFloat angle = previousAngle + copysign(maxTurn, turn);
                dx = cos(angle) * segment;
                dy = sin(angle) * segment;
            }
        }

        if (segment < 0.1) {
            dx = 0;
            dy = 0;
        } else {
            settled = NO;
        }

        _nodes[i] = CGPointMake(previous.x + dx, previous.y + dy);
    }

    return settled;
}

#pragma mark - Morph outline

- (void)updateShape {
    CGFloat size = CGRectGetWidth(self.bounds);
    CGFloat distances[kNodeCount];
    CGFloat length = 0;

    _tailCount = 0;

    for (NSInteger i = 0; i < kNodeCount; i++) {
        if (_tailCount > 0) {
            CGFloat segment = SMTDistance(_nodes[i], _tailPoints[_tailCount - 1]);
            if (segment < 0.5) {
                continue;
            }

            length += segment;
        }

        distances[_tailCount] = length;
        _tailPoints[_tailCount++] = _nodes[i];
    }

    CGFloat stretch = MIN(length / (size * SMTTouchSettings.maxTail), 1.0);
    CGFloat tailRadius = size / 2 * (1.0 - SMTTouchSettings.tailThinning * stretch);
    _headHalfSize = size / 2 * (1.0 - SMTTouchSettings.headThinning * stretch);

    for (NSInteger i = 0; i < _tailCount; i++) {
        _tailRadii[i] = length > 0 ? _headHalfSize + (tailRadius - _headHalfSize) * distances[i] / length : _headHalfSize;
    }

    CGFloat corner = MIN(_cornerRadius * _headHalfSize / (size / 2), _headHalfSize);
    CGFloat tension = stretch * stretch * (3.0 - 2.0 * stretch);
    _headCorner = corner + (_headHalfSize - corner) * tension;
    _blend = size * SMTTouchSettings.blend;

    _shapeLayer.path = [self contourPath];
}

- (CGFloat)fieldAtPoint:(CGPoint)point {
    CGFloat head = [self headDistanceFrom:point];
    CGFloat tail = [self tailDistanceFrom:point];
    CGFloat blend = MAX(_blend - fabs(head - tail), 0) / _blend;

    return MIN(head, tail) - blend * blend * _blend * 0.25;
}

- (CGFloat)headDistanceFrom:(CGPoint)point {
    CGPoint head = _tailPoints[0];
    CGFloat qx = fabs(point.x - head.x) - (_headHalfSize - _headCorner);
    CGFloat qy = fabs(point.y - head.y) - (_headHalfSize - _headCorner);

    return hypot(MAX(qx, 0), MAX(qy, 0)) + MIN(MAX(qx, qy), 0) - _headCorner;
}

- (CGFloat)tailDistanceFrom:(CGPoint)point {
    CGFloat distance = CGFLOAT_MAX;

    for (NSInteger i = 0; i + 1 < _tailCount; i++) {
        CGPoint a = _tailPoints[i];
        CGFloat ra = _tailRadii[i];
        CGFloat rb = _tailRadii[i + 1];
        CGFloat px = point.x - a.x;
        CGFloat py = point.y - a.y;
        CGFloat bx = _tailPoints[i + 1].x - a.x;
        CGFloat by = _tailPoints[i + 1].y - a.y;
        CGFloat lengthSquared = bx * bx + by * by;
        CGFloat taper = ra - rb;
        CGFloat capsule;

        if (lengthSquared <= taper * taper + 1e-6) {
            capsule = MIN(hypot(px, py) - ra, hypot(px - bx, py - by) - rb);
        } else {
            CGFloat across = fabs(px * by - py * bx) / lengthSquared;
            CGFloat along = (px * bx + py * by) / lengthSquared;
            CGFloat side = sqrt(lengthSquared - taper * taper);
            CGFloat k = side * along - taper * across;

            if (k < 0) {
                capsule = sqrt(lengthSquared * (across * across + along * along)) - ra;
            } else if (k > side) {
                capsule = sqrt(lengthSquared * (across * across + along * along + 1.0 - 2.0 * along)) - rb;
            } else {
                capsule = side * across + taper * along - ra;
            }
        }

        distance = MIN(distance, capsule);
    }

    return distance;
}

- (CGPathRef)contourPath CF_RETURNS_NOT_RETAINED {
    SMTGrid grid = [self contourGrid];
    CGFloat *field = [self sampleFieldOnGrid:grid];
    CGPathRef path = [self contourOfField:field grid:grid];
    free(field);

    return path;
}

- (SMTGrid)contourGrid {
    CGFloat step = SMTTouchSettings.gridStep;
    CGFloat margin = _headHalfSize + _blend * 0.25 + 3 * step;
    CGFloat minX = CGFLOAT_MAX, minY = CGFLOAT_MAX, maxX = -CGFLOAT_MAX, maxY = -CGFLOAT_MAX;

    for (NSInteger i = 0; i < _tailCount; i++) {
        minX = MIN(minX, _tailPoints[i].x);
        minY = MIN(minY, _tailPoints[i].y);
        maxX = MAX(maxX, _tailPoints[i].x);
        maxY = MAX(maxY, _tailPoints[i].y);
    }

    CGPoint head = _tailPoints[0];
    SMTGrid grid;
    grid.step = step;
    grid.origin = CGPointMake(head.x - ceil((head.x - minX + margin) / step) * step, head.y - ceil((head.y - minY + margin) / step) * step);
    grid.columns = (NSInteger)ceil((maxX + margin - grid.origin.x) / step) + 1;
    grid.rows = (NSInteger)ceil((maxY + margin - grid.origin.y) / step) + 1;

    return grid;
}

- (CGFloat *)sampleFieldOnGrid:(SMTGrid)grid {
    CGFloat *field = malloc(grid.columns * grid.rows * sizeof(CGFloat));

    for (NSInteger j = 0; j < grid.rows; j++) {
        for (NSInteger i = 0; i < grid.columns; i++) {
            CGFloat value = [self fieldAtPoint:CGPointMake(grid.origin.x + i * grid.step, grid.origin.y + j * grid.step)];
            BOOL border = i == 0 || j == 0 || i == grid.columns - 1 || j == grid.rows - 1;

            field[j * grid.columns + i] = border ? MAX(value, grid.step) : value;
        }
    }

    return field;
}

- (CGPathRef)contourOfField:(CGFloat *)field grid:(SMTGrid)grid CF_RETURNS_NOT_RETAINED {
    NSInteger edgeCount = (grid.columns - 1) * grid.rows + grid.columns * (grid.rows - 1);
    CGPoint *points = malloc(edgeCount * sizeof(CGPoint));
    NSInteger *links = malloc(edgeCount * 2 * sizeof(NSInteger));

    for (NSInteger e = 0; e < edgeCount * 2; e++) {
        links[e] = -1;
    }

    [self linkContourEdgesOfField:field grid:grid points:points links:links];
    CGPathRef path = [self pathByWalkingLinks:links points:points count:edgeCount];

    free(links);
    free(points);

    return path;
}

- (void)linkContourEdgesOfField:(CGFloat *)field grid:(SMTGrid)grid points:(CGPoint *)points links:(NSInteger *)links {
    NSInteger columns = grid.columns;
    NSInteger horizontalEdges = (columns - 1) * grid.rows;

    const NSInteger cases[16][4] = {
        {-1, -1, -1, -1}, {3, 2, -1, -1}, {2, 1, -1, -1}, {3, 1, -1, -1},
        {0, 1, -1, -1}, {-1, -1, -1, -1}, {0, 2, -1, -1}, {3, 0, -1, -1},
        {3, 0, -1, -1}, {0, 2, -1, -1}, {-1, -1, -1, -1}, {0, 1, -1, -1},
        {3, 1, -1, -1}, {2, 1, -1, -1}, {3, 2, -1, -1}, {-1, -1, -1, -1}
    };

    for (NSInteger j = 0; j + 1 < grid.rows; j++) {
        for (NSInteger i = 0; i + 1 < columns; i++) {
            CGFloat tl = field[j * columns + i];
            CGFloat tr = field[j * columns + i + 1];
            CGFloat br = field[(j + 1) * columns + i + 1];
            CGFloat bl = field[(j + 1) * columns + i];
            NSInteger index = (tl < 0) * 8 + (tr < 0) * 4 + (br < 0) * 2 + (bl < 0);

            NSInteger sides[4];
            memcpy(sides, cases[index], sizeof(sides));

            if (index == 5 || index == 10) {
                BOOL centerInside = (tl + tr + br + bl) / 4 < 0;
                NSInteger joined[4] = {3, 0, 2, 1};
                NSInteger split[4] = {3, 2, 0, 1};
                memcpy(sides, (index == 5) == centerInside ? joined : split, sizeof(sides));
            }

            for (NSInteger s = 0; s < 4 && sides[s] >= 0; s += 2) {
                NSInteger pair[2];

                for (NSInteger k = 0; k < 2; k++) {
                    NSInteger side = sides[s + k];
                    BOOL horizontal = side == 0 || side == 2;
                    NSInteger ai = i + (side == 1), aj = j + (side == 2);
                    NSInteger bi = ai + horizontal, bj = aj + !horizontal;
                    NSInteger edge = horizontal ? aj * (columns - 1) + ai : horizontalEdges + aj * columns + ai;

                    CGFloat va = field[aj * columns + ai];
                    CGFloat vb = field[bj * columns + bi];
                    CGFloat t = va / (va - vb);

                    points[edge] = CGPointMake(grid.origin.x + (ai + (bi - ai) * t) * grid.step, grid.origin.y + (aj + (bj - aj) * t) * grid.step);
                    pair[k] = edge;
                }

                links[pair[0] * 2 + (links[pair[0] * 2] >= 0)] = pair[1];
                links[pair[1] * 2 + (links[pair[1] * 2] >= 0)] = pair[0];
            }
        }
    }
}

- (CGPathRef)pathByWalkingLinks:(NSInteger *)links points:(CGPoint *)points count:(NSInteger)edgeCount CF_RETURNS_NOT_RETAINED {
    CGMutablePathRef path = CGPathCreateMutable();
    CGPoint *loop = malloc(edgeCount * sizeof(CGPoint));
    BOOL *visited = calloc(edgeCount, sizeof(BOOL));
    CGFloat offsetX = CGRectGetMidX(self.bounds) - _tailPoints[0].x;
    CGFloat offsetY = CGRectGetMidY(self.bounds) - _tailPoints[0].y;

    for (NSInteger start = 0; start < edgeCount; start++) {
        if (visited[start] || links[start * 2] < 0) {
            continue;
        }

        NSInteger count = 0;
        NSInteger previous = -1;
        NSInteger current = start;

        while (current >= 0 && !visited[current]) {
            visited[current] = YES;
            loop[count++] = CGPointMake(points[current].x + offsetX, points[current].y + offsetY);

            NSInteger next = links[current * 2] != previous ? links[current * 2] : links[current * 2 + 1];
            previous = current;
            current = next;
        }

        if (count >= 3) {
            [self addSmoothLoop:loop count:count toPath:path];
        }
    }

    free(visited);
    free(loop);

    return (CGPathRef)CFAutorelease(path);
}

- (void)addSmoothLoop:(CGPoint *)loop count:(NSInteger)count toPath:(CGMutablePathRef)path {
    CGPoint last = loop[count - 1];
    CGPathMoveToPoint(path, NULL, (last.x + loop[0].x) / 2, (last.y + loop[0].y) / 2);

    for (NSInteger p = 0; p < count; p++) {
        CGPoint next = loop[(p + 1) % count];
        CGPathAddQuadCurveToPoint(path, NULL, loop[p].x, loop[p].y, (loop[p].x + next.x) / 2, (loop[p].y + next.y) / 2);
    }

    CGPathCloseSubpath(path);
}

#pragma mark - Comet

- (void)addTrailPoint:(CGPoint)point {
    if (_trailCount > 0 && SMTDistance(point, _trailPoints[_trailCount - 1]) < SMTTouchSettings.trailSpacing) {
        return;
    }

    if (_trailCount == kMaxTrailPoints) {
        [self removeOldestTrailPoints:1];
    }

    _trailPoints[_trailCount] = point;
    _trailTimes[_trailCount] = CACurrentMediaTime();
    _trailCount++;
}

- (void)removeOldestTrailPoints:(NSInteger)count {
    _trailCount -= count;
    memmove(_trailPoints, _trailPoints + count, _trailCount * sizeof(CGPoint));
    memmove(_trailTimes, _trailTimes + count, _trailCount * sizeof(CFTimeInterval));
}

- (void)updateTrail {
    CFTimeInterval now = CACurrentMediaTime();
    CFTimeInterval lifetime = SMTTouchSettings.trailLifetime;

    NSInteger expired = 0;
    while (expired < _trailCount && now - _trailTimes[expired] >= lifetime) {
        expired++;
    }

    if (expired > 0) {
        [self removeOldestTrailPoints:expired];
    }

    CGPoint points[kMaxTrailPoints + 1];
    CGFloat widths[kMaxTrailPoints + 1];
    CGFloat halfWidth = CGRectGetWidth(self.bounds) * SMTTouchSettings.trailWidth / 2;
    NSInteger count = 0;

    for (NSInteger i = 0; i < _trailCount; i++) {
        CGFloat life = 1.0 - (now - _trailTimes[i]) / lifetime;
        points[count] = _trailPoints[i];
        widths[count++] = halfWidth * pow(MAX(life, 0), 1.5);
    }

    if (!_dismissed && count > 0 && SMTDistance(_nodes[0], points[count - 1]) > 0.5) {
        points[count] = _nodes[0];
        widths[count++] = halfWidth;
    }

    _trailLayer.path = count >= 2 ? [self ribbonPathThrough:points widths:widths count:count] : nil;

    if (!_dismissed && _trailLayer.mask) {
        ((CAShapeLayer *)_trailLayer.mask).path = [self trailMaskPath];
    }
}

- (CGPathRef)trailMaskPath CF_RETURNS_NOT_RETAINED {
    CGRect bounds = self.bounds;
    CGAffineTransform toSuperview = CGAffineTransformMakeTranslation(self.center.x - CGRectGetMidX(bounds), self.center.y - CGRectGetMidY(bounds));

    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectInset(self.superview.bounds, -CGRectGetWidth(bounds), -CGRectGetHeight(bounds)));

    if (_morph) {
        CGPathAddPath(path, &toSuperview, _shapeLayer.path);
    } else {
        CGPathAddRoundedRect(path, &toSuperview, bounds, _cornerRadius, _cornerRadius);
    }

    return (CGPathRef)CFAutorelease(path);
}

- (void)releaseTrail {
    _trailLayer.mask = nil;

    CGFloat radius = CGRectGetWidth(self.bounds) / 2;
    while (_trailCount > 0 && SMTDistance(_trailPoints[_trailCount - 1], _nodes[0]) < radius) {
        _trailCount--;
    }
}

- (CGPathRef)ribbonPathThrough:(CGPoint *)points widths:(CGFloat *)widths count:(NSInteger)count CF_RETURNS_NOT_RETAINED {
    CGPoint left[kMaxTrailPoints + 1];
    CGPoint right[kMaxTrailPoints + 1];
    CGFloat angle = 0;

    for (NSInteger i = 0; i < count; i++) {
        CGPoint behind = points[MAX(i - 1, 0)];
        CGPoint ahead = points[MIN(i + 1, count - 1)];

        if (SMTDistance(ahead, behind) > 0.01) {
            angle = atan2(ahead.y - behind.y, ahead.x - behind.x);
        }

        CGFloat nx = -sin(angle) * widths[i];
        CGFloat ny = cos(angle) * widths[i];
        left[i] = CGPointMake(points[i].x + nx, points[i].y + ny);
        right[i] = CGPointMake(points[i].x - nx, points[i].y - ny);
    }

    CGMutablePathRef path = CGPathCreateMutable();
    NSInteger last = count - 1;

    CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);

    for (NSInteger i = 1; i < last; i++) {
        CGPathAddQuadCurveToPoint(path, NULL, left[i].x, left[i].y, (left[i].x + left[i + 1].x) / 2, (left[i].y + left[i + 1].y) / 2);
    }

    CGPathAddLineToPoint(path, NULL, left[last].x, left[last].y);
    CGPathAddArc(path, NULL, points[last].x, points[last].y, widths[last], angle + M_PI_2, angle - M_PI_2, true);

    for (NSInteger i = last - 1; i > 0; i--) {
        CGPathAddQuadCurveToPoint(path, NULL, right[i].x, right[i].y, (right[i].x + right[i - 1].x) / 2, (right[i].y + right[i - 1].y) / 2);
    }

    CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
    CGPathCloseSubpath(path);

    return (CGPathRef)CFAutorelease(path);
}

@end
