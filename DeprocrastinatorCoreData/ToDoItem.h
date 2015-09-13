//
//  ToDoItem.h
//  DeprocrastinatorCoreData
//
//  Created by Rachel Schneebaum on 9/12/15.
//  Copyright (c) 2015 Rachel Schneebaum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ToDoItem : NSManagedObject

@property (nonatomic, retain) NSNumber * isChecked;
@property (nonatomic, retain) NSNumber * priority;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * displayOrder;

@end
