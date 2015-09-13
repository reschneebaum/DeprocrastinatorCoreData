//
//  ViewController.m
//  DeprocrastinatorCoreData
//
//  Created by Rachel Schneebaum on 9/11/15.
//  Copyright (c) 2015 Rachel Schneebaum. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ToDoViewController.h"
#import "ToDoItem.h"
#import "AppDelegate.h"

@interface ToDoViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *addItemTextField;
@property (weak, nonatomic) IBOutlet UITableView *toDoItemsTableView;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic) NSArray *items;
@property NSManagedObjectContext *moc;

@end

@implementation ToDoViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    self.moc = delegate.managedObjectContext;
    self.addButton.enabled = false;

    //Add a right swipe gesture recognizer
    UISwipeGestureRecognizer *recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                action:@selector(handleSwipeRight:)];
    recognizer.delegate = self;
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.toDoItemsTableView addGestureRecognizer:recognizer];

    [self loadToDoItems];
//    [self populateListIfEmpty];
}

-(void)loadToDoItems {
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([ToDoItem class])];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"displayOrder" ascending:true]];
    self.items = [self.moc executeFetchRequest:request error:nil];
    [self.toDoItemsTableView reloadData];
}

-(void)setItems:(NSMutableArray *)items {
    _items = items;
    [self.toDoItemsTableView reloadData];
}

-(void)populateListIfEmpty {
    //  fills list for testing purposes
    if (self.items.count <= 0) {
        NSInteger numberOfItems = 30;
        for (NSInteger i = 1; i <= numberOfItems; i++) {
            NSString *title = [NSString stringWithFormat:@"Thing #%ld", (long)i];
            ToDoItem *item = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([ToDoItem class]) inManagedObjectContext:self.moc];
            item.title = title;
            item.priority = 0;
            item.isChecked = [NSNumber numberWithBool:NO];
            item.displayOrder = [NSNumber numberWithInteger:i];
            [self.moc save:nil];
            [self loadToDoItems];
        }
    }
}

- (void)handleSwipeRight:(UISwipeGestureRecognizer *)gestureRecognizer {
    //Get location of the swipe
    CGPoint location = [gestureRecognizer locationInView:self.toDoItemsTableView];

    //Get the corresponding index path within the table view
    NSIndexPath *indexPath = [self.toDoItemsTableView indexPathForRowAtPoint:location];

    if (indexPath) {
        ToDoItem *item = self.items[indexPath.row];
        int temp = [item.priority intValue];
        if (temp < 3) {
            temp++;
            [item setPriority:[NSNumber numberWithInt:temp]];
        } else {
            [item setPriority:0];
        }
        [self.moc save:nil];
        [self loadToDoItems];
    }
}

#pragma mark - UIGestureRecognizerDelegate
#pragma mark -

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    //  allow right swipe/swipe to delete/scroll to work at the same time
    return YES;
}

#pragma mark - UITableView delegate methods
#pragma mark -

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ToDoCell"];
    ToDoItem *item = self.items[indexPath.row];
    cell.textLabel.text = item.title;
    cell.textLabel.font = [UIFont fontWithName:@"Avenir Next" size:15];

    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    ToDoItem *item = self.items[indexPath.row];
    //  adds or removes checkmark 9when row is tapped0
    if ([item.isChecked isEqual:@1]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    //  sets background color based on priority (on right swipe)
    if ([item.priority isEqual:@1]) {
        cell.backgroundColor = [UIColor colorWithRed:90.0/255 green:185.0/255 blue:130.0/255 alpha:0.4];
    } else if ([item.priority isEqual:@2]) {
        cell.backgroundColor = [UIColor colorWithRed:222.0/255 green:180.0/255 blue:82.0/255 alpha:0.4];
    } else if ([item.priority isEqual:@3]) {
        cell.backgroundColor = [UIColor colorWithRed:200.0/255 green:50.0/255 blue:50.0/255 alpha:0.4];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //  delete item from store
        [self.moc deleteObject:self.items[indexPath.row]];

        //  update tableview by removing item from array
        [tableView beginUpdates];
        id tmp = [self.items mutableCopy];
        [tmp removeObjectAtIndex:indexPath.row];
        self.items = [tmp copy];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        [tableView endUpdates];

        [self.moc save:nil];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ToDoItem *item = self.items[indexPath.row];
    //  when row is selected, set value of "isChecked"
    if ([item.isChecked isEqual:@1]) {
        [item setValue:@0 forKey:@"isChecked"];
        [self.moc save:nil];
    } else {
        [item setValue:@1 forKey:@"isChecked"];
        [self.moc save:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:false];
    [self loadToDoItems];
}


-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    ToDoItem *toDoItem = [self.items objectAtIndex:sourceIndexPath.row];
    //  change order of self.items array
    [tableView beginUpdates];
    id tmp = [self.items mutableCopy];
    [tmp removeObjectAtIndex:sourceIndexPath.row];
    [tmp insertObject:toDoItem atIndex:destinationIndexPath.row];
    self.items = [tmp copy];

    //  delete and reinsert moved row in tableview
    [tableView deleteRowsAtIndexPaths:@[sourceIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    [tableView insertRowsAtIndexPaths:@[destinationIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    [tableView endUpdates];

    //  change display order of all items in array to reflect adjustments
    for (ToDoItem *item in self.items) {
        [item setValue:[NSNumber numberWithInteger:[self.items indexOfObject:item]] forKey:@"displayOrder"];
    }
    [self.moc save:nil];
    [self loadToDoItems];
}

#pragma mark - IBActions
#pragma mark -

- (IBAction)onAddButtonPressed:(UIButton *)sender {
    ToDoItem *newItem = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([ToDoItem class]) inManagedObjectContext:self.moc];
    newItem.title = self.addItemTextField.text;
    newItem.priority = 0;
    newItem.isChecked = 0;

    //  if no items exist, new item gets display order 1; otherwise, item's display order is equal to the number of existing items+1 (added to end)
    if (self.items.count <= 0) {
        newItem.displayOrder = [NSNumber numberWithInteger:1];
    } else {
        newItem.displayOrder = [NSNumber numberWithInteger:self.items.count + 1];
    }
    [self.moc save:nil];
    [self loadToDoItems];
    [self.addItemTextField endEditing:YES];
    [self.addItemTextField resignFirstResponder];
    self.addItemTextField.text = @"";
    self.addButton.enabled = false;
}

- (IBAction)onAddButtonTextFieldEdited:(UITextField *)sender {
    if ([self.addItemTextField hasText]) {
        self.addButton.enabled = true;
    } else {
        self.addButton.enabled = false;
    }
}

- (IBAction)onEditButtonPressed:(UIBarButtonItem *)sender {
    if (self.editing == true) {
        self.editButton.title = @"Edit";
        [self.toDoItemsTableView setEditing:false animated:true];
        self.editing = false;
    } else {
        self.editButton.title = @"Done";
        [self.toDoItemsTableView setEditing:true animated:true];
        self.editing = true;
    }
}


@end
