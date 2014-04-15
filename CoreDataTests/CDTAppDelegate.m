//
//  CDTAppDelegate.m
//  CoreDataTests
//
//  Created by Sergey Sedov on 14.04.14.
//
//

#import "CDTAppDelegate.h"
#import <CoreData/CoreData.h>

@implementation CDTAppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Override point for customization after application launch.
//  [self checkoVersionWithSampleDB];
  [self createPersistentStoreCoordinator];

  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  // Sent when the application is about to move from active to inactive state.
  // This can occur for certain types of temporary interruptions (such as an
  // incoming phone call or SMS message) or when the user quits the application
  // and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down
  // OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate
  // timers, and store enough application state information to restore your
  // application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called
  // instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the inactive state;
  // here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Restart any tasks that were paused (or not yet started) while the
  // application was inactive. If the application was previously in the
  // background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if
  // appropriate. See also applicationDidEnterBackground:.
}

- (void)checkoVersionWithSampleDB {
  NSString *docDir = NSSearchPathForDirectoriesInDomains(
      NSDocumentDirectory, NSUserDomainMask, YES)[0];
  NSString *dbPath = [docDir stringByAppendingPathComponent:@"sample.db"];
  NSError *error = nil;

  if ([[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
    [[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil];
  }

  if (![[NSFileManager defaultManager]
          copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"sample"
                                                         ofType:@"db"]
                  toPath:dbPath
                   error:&error]) {
    NSLog(@"error copy: %@", error);
  }

  NSManagedObjectModel *model =
      [NSManagedObjectModel mergedModelFromBundles:nil];

  NSURL *sourceURL = [NSURL fileURLWithPath:dbPath];
  NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator
      metadataForPersistentStoreOfType:NSSQLiteStoreType
                                   URL:sourceURL
                                 error:&error];

  BOOL isCompatible =
      [model isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata];
  NSLog(@"compatible: %d", isCompatible);

  NSMutableDictionary *newMetadata = [sourceMetadata mutableCopy];
  newMetadata[NSStoreModelVersionHashesKey] = [model entityVersionHashesByName];
  newMetadata[NSStoreModelVersionIdentifiersKey] =
      [[model versionIdentifiers] allObjects];
  newMetadata[@"NSPersistenceFrameworkVersion"] = @(479);
  newMetadata[@"_NSAutoVacuumLevel"] = @(2);
  newMetadata[@"NSStoreModelVersionHashesVersion"] = @(3);
  newMetadata[NSStoreTypeKey] = NSSQLiteStoreType;

  [NSPersistentStoreCoordinator setMetadata:newMetadata
                   forPersistentStoreOfType:NSSQLiteStoreType
                                        URL:sourceURL
                                      error:&error];
  sourceMetadata = [NSPersistentStoreCoordinator
      metadataForPersistentStoreOfType:NSSQLiteStoreType
                                   URL:sourceURL
                                 error:&error];
  isCompatible =
      [model isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata];
  NSLog(@"compatible2: %d", isCompatible);
}

- (void)createPersistentStoreCoordinator {
  NSManagedObjectModel *model =
      [NSManagedObjectModel mergedModelFromBundles:nil];

  NSPersistentStoreCoordinator *coordinator =
      [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
  NSMutableDictionary *pragmaOptions = [NSMutableDictionary dictionary];
  [pragmaOptions setObject:@"DELETE" forKey:@"journal_mode"];

  NSDictionary *options = [NSDictionary
      dictionaryWithObjectsAndKeys:pragmaOptions, NSSQLitePragmasOption, nil];

  NSError *error = nil;

  NSString *docDir = NSSearchPathForDirectoriesInDomains(
      NSDocumentDirectory, NSUserDomainMask, YES)[0];

    NSString *dbPath = [docDir stringByAppendingPathComponent:@"data.db"];
    if([[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil];
    }
  NSURL *url = [NSURL
      fileURLWithPath:[docDir stringByAppendingPathComponent:@"sample.db"]];
  if ([coordinator addPersistentStoreWithType:NSSQLiteStoreType
                                configuration:nil
                                          URL:url
                                      options:options
                                        error:&error]) {
    NSLog(@"db path: %@", url);

    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator
        metadataForPersistentStoreOfType:NSSQLiteStoreType
                                     URL:url
                                   error:&error];
    BOOL compat =
        [model isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata];

    NSManagedObjectContext *context = [[NSManagedObjectContext alloc]
        initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = coordinator;

    NSManagedObject *card =
        [NSEntityDescription insertNewObjectForEntityForName:@"Card"
                                      inManagedObjectContext:context];
      [card setValue:@"1" forKey:@"name"];
      [card setValue:[NSDate date] forKey:@"createdAt"];
      [card setValue:@YES forKey:@"active"];
    [context save:&error];

    NSFetchRequest *request =
        [NSFetchRequest fetchRequestWithEntityName:@"Card"];
    NSArray *cards = [context executeFetchRequest:request error:&error];

    NSManagedObject *spec =
        [NSEntityDescription insertNewObjectForEntityForName:@"Spec"
                                      inManagedObjectContext:context];
    [spec setValue:@"2" forKey:@"name"];
    [context save:&error];

    request = [NSFetchRequest fetchRequestWithEntityName:@"Spec"];
    NSArray *specs = [context executeFetchRequest:request error:&error];
      
    int i = 0;
  } else {
    NSLog(@"error: %@", error);
  }
}

@end
