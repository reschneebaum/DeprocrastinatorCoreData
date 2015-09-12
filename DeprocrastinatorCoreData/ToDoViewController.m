//
//  ViewController.m
//  DeprocrastinatorCoreData
//
//  Created by Rachel Schneebaum on 9/11/15.
//  Copyright (c) 2015 Rachel Schneebaum. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ToDoViewController.h"
#import "ToDoTableViewCell.h"
#import "ToDoItem.h"
#import "AppDelegate.h"

@interface ToDoViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *addItemTextField;
@property (weak, nonatomic) IBOutlet UITableView *toDoItemsTableView;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property NSArray *items;
@property NSManagedObjectContext *moc;

@end

@implementation ToDoViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    self.moc = delegate.managedObjectContext;
//    self.items = [NSArray new];
    self.addButton.enabled = false;

    //Add a right swipe gesture recognizer
    UISwipeGestureRecognizer *recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                action:@selector(handleSwipeRight:)];
    recognizer.delegate = self;
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.toDoItemsTableView addGestureRecognizer:recognizer];

    [self loadToDoItems];
    [self populateListIfEmpty];
}

-(void)loadToDoItems {
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ToDoItem"];
    self.items = [self.moc executeFetchRequest:request error:nil];
    [self.toDoItemsTableView reloadData];
}

-(void)populateListIfEmpty {
    if (self.items.count <= 0) {
        NSInteger numberOfItems = 30;
        for (NSInteger i = 1; i <= numberOfItems; i++) {
            NSString *title = [NSString stringWithFormat:@"Thing #%ld", (long)i];
            ToDoItem *item = [NSEntityDescription insertNewObjectForEntityForName:@"ToDoItem" inManagedObjectContext:self.moc];
            item.title = title;
            item.priority = 0;
            item.isChecked = [NSNumber numberWithBool:NO];
            [self.moc save:nil];
            [self loadToDoItems];
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate
#pragma mark -

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - UITableView delegate methods
#pragma mark -

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"# items in numberofrowsinsection: %lu", (unsigned long)self.items.count);
    return self.items.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ToDoCell"];
    ToDoItem *item = self.items[indexPath.row];
    cell.textLabel.text = item.title;

    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    ToDoItem *item = self.items[indexPath.row];

    if ([item.isChecked isEqual:@1]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.moc deleteObject:self.items[indexPath.row]];

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
    NSLog(@"when selected, is cell checked: %@", item.isChecked);
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
    [tableView beginUpdates];

    id tmp = [self.items mutableCopy];
    [tmp removeObjectAtIndex:sourceIndexPath.row];
    [tmp insertObject:toDoItem atIndex:destinationIndexPath.row];
    self.items = [tmp copy];

    [tableView deleteRowsAtIndexPaths:@[sourceIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    [tableView insertRowsAtIndexPaths:@[destinationIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    [tableView endUpdates];

    [self.moc save:nil];
    [self loadToDoItems];
}

#pragma mark - IBActions
#pragma mark -

- (IBAction)onAddButtonPressed:(UIButton *)sender {
    ToDoItem *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"ToDoItem" inManagedObjectContext:self.moc];
    newItem.title = self.addItemTextField.text;
    newItem.priority = 0;
    newItem.isChecked = 0;
    [self.moc save:nil];
    [self loadToDoItems];
    [self.addItemTextField endEditing:YES];
    [self.addItemTextField resignFirstResponder];
    self.addItemTextField.text = @"";
//    [self.toDoItemsTableView reloadData];
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
