

#import "JRGridLayoutWithStickyCellsLayout.h"

@interface NSIndexPath (JRGridLayoutWithStickyCellsLayout)
@property (nonatomic, readonly) NSInteger tableRow;
@property (nonatomic, readonly) NSInteger tableColumn;
+(instancetype) indexPathForTableRow:(NSInteger) tableRow tableColumn:(NSInteger) tableColumn;
@end
@implementation NSIndexPath (JRGridLayoutWithStickyCellsLayout)

-(NSInteger) tableRow{
    return self.section;
}
-(NSInteger) tableColumn{
    return self.row;
}
+(instancetype) indexPathForTableRow:(NSInteger) tableRow tableColumn:(NSInteger) tableColumn{
    return [NSIndexPath indexPathForRow:tableColumn inSection:tableRow];
}
@end


@interface JRGridLayoutWithStickyCellsLayout()
@property (nonatomic, strong) NSArray* columnWidths;
@property (nonatomic, strong) NSArray* rowHeights;
@property (nonatomic, strong) NSArray* columnOriginsX;
@property (nonatomic, strong) NSArray* rowOriginsY;

@property (nonatomic, assign) BOOL hasColumnRowsAndHeights;

@property (nonatomic, assign) BOOL hasDynamicRowHeight;
@property (nonatomic, assign) BOOL hasDynamicColumnWidth;
@end

@implementation JRGridLayoutWithStickyCellsLayout
-(void) getCollumnAndRowHeights{
    self.hasDynamicRowHeight = [self.collectionView.delegate respondsToSelector:@selector(collectionView:heightForRowAtIndex:)];
    self.hasDynamicColumnWidth = [self.collectionView.delegate respondsToSelector:@selector(collectionView:widthForColumAtIndex:)];
    
    if(self.hasDynamicRowHeight){
        CGFloat offset = 0;
        
        NSMutableArray* array = [NSMutableArray array];
        NSMutableArray* origins = [NSMutableArray array];
        for (NSUInteger section = 0; section < self.collectionView.numberOfSections; section ++) {
            CGFloat heigth = [((id<JRGridLayoutWithStickyCellsLayoutDelegate>)(self.collectionView.delegate)) collectionView:self.collectionView heightForRowAtIndex:section];
            [array addObject:@(heigth)];
            [origins addObject:@(offset)];
            offset += heigth;
            
        }
        self.rowHeights = array;
        self.rowOriginsY = origins;
    }
    if(self.hasDynamicColumnWidth){
        CGFloat offset = 0;
        
        NSMutableArray* array = [NSMutableArray array];
        NSMutableArray* origins = [NSMutableArray array];
        
        for (NSUInteger column = 0; column < [self.collectionView numberOfItemsInSection:0]; column ++) {
            CGFloat heigth = [((id<JRGridLayoutWithStickyCellsLayoutDelegate>)(self.collectionView.delegate)) collectionView:self.collectionView widthForColumAtIndex:column];
            [array addObject:@(heigth)];
            [origins addObject:@(offset)];
            offset += heigth;
        }
        self.columnWidths = array;
        self.columnOriginsX = origins;
    }
    self.hasColumnRowsAndHeights = YES;
}
-(CGFloat) columnWidthAtIndex:(NSInteger)index{
    if (self.hasDynamicColumnWidth) {
        return [self.columnWidths[index] doubleValue];
    }else{
        return self.itemSize.width;
    }
}
-(CGFloat) rowHeightAtIndex:(NSInteger) index{
    if (self.hasDynamicRowHeight) {
        return [self.rowHeights[index] doubleValue];
    }else{
        return self.itemSize.height;
    }
}
-(CGFloat) originXForColumnAtIndex:(NSInteger) column{
    CGFloat x = 0;
    if (self.hasDynamicColumnWidth) {
        x = [self.columnOriginsX[column] doubleValue];
    }else{
        x = column * self.itemSize.width;
    }
    return x;
}
-(CGFloat) originYForRowAtIndex:(NSInteger) row{
    CGFloat y =0;
    if (self.hasDynamicRowHeight) {
        y = [self.rowOriginsY[row] doubleValue];
    }else{
        y = row * self.itemSize.height;
    }
    return y;
}
-(CGRect) frameForItemAtIndexPath:(NSIndexPath*) indexPath{
    CGRect frame = CGRectZero;
    frame.origin.x = [self originXForColumnAtIndex:indexPath.tableColumn];
    frame.origin.y = [self originYForRowAtIndex:indexPath.tableRow];
    frame.size.width =  [self columnWidthAtIndex:indexPath.tableColumn];
    frame.size.height =   [self rowHeightAtIndex:indexPath.tableRow];
    
    return frame;
}
-(NSInteger) columnIndexForXPosition:(CGFloat) originX{
    if (self.hasDynamicColumnWidth) {
        NSInteger index = [self.columnOriginsX indexOfObject:@(originX) inSortedRange:NSMakeRange(0, self.columnOriginsX.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(NSNumber*  _Nonnull obj1, NSNumber*  _Nonnull obj2) {
            return [obj1 compare:obj2];
        }];
        return index;
    }else{
        if (self.itemSize.width > 0) {
            return (NSInteger)floor(originX/self.itemSize.width);
        }
    }
    return 0;
}
-(NSInteger) rowIndexForYPosition:(CGFloat) originY{
    if (self.hasDynamicRowHeight) {
        NSInteger index = [self.rowOriginsY indexOfObject:@(originY) inSortedRange:NSMakeRange(0, self.rowOriginsY.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(NSNumber*  _Nonnull obj1, NSNumber*  _Nonnull obj2) {
            return [obj1 compare:obj2];
        }];
        return index;
    }else{
        if (self.itemSize.height > 0) {
            return (NSInteger)floor(originY/self.itemSize.height);
        }
    }
    return 0;
}

-(void) getCollumnAndRowHeightsIfNeeded{
    if (!self.hasColumnRowsAndHeights) {
        [self getCollumnAndRowHeights];
    }
}
-(void) invalidateLayout{
    [super invalidateLayout];
   
}
-(void) invalidateLayoutWithContext:(UICollectionViewLayoutInvalidationContext *)context{
    [super invalidateLayoutWithContext:context];
    if(context.invalidatedItemIndexPaths || context.invalidateEverything || context.invalidateDataSourceCounts ){
        self.hasColumnRowsAndHeights = NO;
        [self getCollumnAndRowHeights];
    }
}
-(CGSize) collectionViewContentSize{
    [self getCollumnAndRowHeightsIfNeeded];
    
    CGFloat width = 0;
    if (self.hasDynamicColumnWidth) {
        width = [[self.columnOriginsX lastObject] doubleValue] + [[self.columnWidths lastObject] doubleValue];
    }else{
        width = self.itemSize.width * [self.collectionView numberOfItemsInSection:0];
    }
    CGFloat height = 0;
    if (self.hasDynamicRowHeight) {
        height = [[self.rowOriginsY lastObject] doubleValue] + [[self.rowHeights lastObject] doubleValue];
    }else{
        height = self.itemSize.height * [self.collectionView numberOfSections];
    }
    
    return CGSizeMake(width, height);
}

-(UICollectionViewLayoutAttributes*) layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath{
    [self getCollumnAndRowHeightsIfNeeded];
    UICollectionViewLayoutAttributes* attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    CGRect frame =  [self frameForItemAtIndexPath:indexPath];
    
    attributes.zIndex = 0;
    if (indexPath.tableColumn < self.columnsToStickOnLeft) {
        attributes.zIndex+= 1;
        if (self.collectionView.contentOffset.x > 0) {
            frame.origin.x += self.collectionView.contentOffset.x;
        }
        CGFloat adjustment = self.collectionView.contentOffset.x + self.collectionView.contentInset.left;
        if (adjustment < 0) {
            adjustment = 0;
        }
        if (adjustment > self.collectionView.contentInset.left) {
            adjustment = self.collectionView.contentInset.left;
        }
        
        frame.origin.x += adjustment;
        
    }
    if (indexPath.tableRow < self.rowsToStickOnTop) {
        attributes.zIndex+= 2;
        if (self.collectionView.contentOffset.y > 0) {
            frame.origin.y += self.collectionView.contentOffset.y;
            
        }
        CGFloat adjustment = self.collectionView.contentOffset.y + self.collectionView.contentInset.top;
        if (adjustment < 0) {
            adjustment = 0;
        }
        if (adjustment > self.collectionView.contentInset.top) {
            adjustment = self.collectionView.contentInset.top;
        }
        
        frame.origin.y += adjustment;

    }
    
    attributes.frame = frame;
    return attributes;
    
}
-(NSIndexSet*) visibileColumnsInRect:(CGRect) rect{
    NSMutableIndexSet* toReturn = [NSMutableIndexSet indexSet];
    
    NSInteger firstColumn = [self columnIndexForXPosition:CGRectGetMinX(rect)];
    if (firstColumn > 0) {
        firstColumn --;
    }
    NSInteger lastColumn = [self columnIndexForXPosition:CGRectGetMaxX(rect)] +1;
    [toReturn addIndexesInRange:NSMakeRange(firstColumn, lastColumn - firstColumn)];
    [toReturn addIndexesInRange:NSMakeRange(0, self.columnsToStickOnLeft)];
    
    return toReturn;
}
- (NSIndexSet*)visibileRowsInRect:(CGRect)rect {
    NSMutableIndexSet* toReturn = [NSMutableIndexSet indexSet];

    NSInteger firstRow = [self rowIndexForYPosition:CGRectGetMinY(rect)];
    if (firstRow > 0) {
        firstRow --;
    }
    NSInteger lastRow = [self rowIndexForYPosition:CGRectGetMaxY(rect)] + 1;
    
    [toReturn addIndexesInRange:NSMakeRange(firstRow, lastRow - firstRow)];
    [toReturn addIndexesInRange:NSMakeRange(0, self.rowsToStickOnTop)];
    return toReturn;
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect{
    [self getCollumnAndRowHeightsIfNeeded];
    NSMutableArray* items = [NSMutableArray array];
    NSIndexSet* visibleColums = [self visibileColumnsInRect:rect];
    NSIndexSet* visibleRows = [self visibileRowsInRect:rect];
    [visibleColums enumerateIndexesUsingBlock:^(NSUInteger column, BOOL * _Nonnull stop) {
       [visibleRows enumerateIndexesUsingBlock:^(NSUInteger row, BOOL * _Nonnull stop) {
           if ([self.collectionView numberOfSections] > row) {
               if ([self.collectionView numberOfItemsInSection:row] > column) {
                   [items addObject:[self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForTableRow:row tableColumn:column]]];
               }
           }
       }];
    }];
    return items;
}
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds{
    return YES;
}


@end
