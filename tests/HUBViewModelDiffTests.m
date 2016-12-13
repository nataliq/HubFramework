/*
 *  Copyright (c) 2016 Spotify AB.
 *
 *  Licensed to the Apache Software Foundation (ASF) under one
 *  or more contributor license agreements.  See the NOTICE file
 *  distributed with this work for additional information
 *  regarding copyright ownership.  The ASF licenses this file
 *  to you under the Apache License, Version 2.0 (the
 *  "License"); you may not use this file except in compliance
 *  with the License.  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */


#import "HUBViewModelDiff.h"
#import "HUBIdentifier.h"
#import "HUBComponentModelImplementation.h"
#import "HUBViewModelImplementation.h"

#import <XCTest/XCTest.h>

@interface HUBViewModelDiffTests : XCTestCase

@end

@implementation HUBViewModelDiffTests

- (id<HUBComponentModel>)createComponentModelWithIdentifier:(NSString *)identifier
                                                 customData:(nullable NSDictionary *)customData
{
    HUBIdentifier * const componentIdentifier = [[HUBIdentifier alloc] initWithNamespace:@"namespace" name:@"name"];
    return [[HUBComponentModelImplementation alloc] initWithIdentifier:identifier
                                                                  type:HUBComponentTypeBody
                                                                 index:0
                                                       groupIdentifier:nil
                                                   componentIdentifier:componentIdentifier
                                                     componentCategory:HUBComponentCategoryBanner
                                                                 title:@"title"
                                                              subtitle:@"subtitle"
                                                        accessoryTitle:nil
                                                       descriptionText:nil
                                                         mainImageData:nil
                                                   backgroundImageData:nil
                                                       customImageData:@{}
                                                                  icon:nil
                                                                target:nil
                                                              metadata:nil
                                                           loggingData:nil
                                                            customData:customData
                                                                parent:nil];
}

- (id<HUBViewModel>)createViewModelWithIdentifier:(NSString *)identifier components:(NSArray<id<HUBComponentModel>> *)components
{
    UINavigationItem * const navigationItem = [[UINavigationItem alloc] initWithTitle:@"Title"];
    
    return [[HUBViewModelImplementation alloc] initWithIdentifier:identifier
                                                   navigationItem:navigationItem
                                             headerComponentModel:nil
                                              bodyComponentModels:components
                                           overlayComponentModels:@[]
                                                       customData:@{@"custom": @"data"}];
}

- (void)testInsertionsMyers
{
    [self runInsertionsTestWithAlgorithm:HUBDiffMyersAlgorithm];
}

- (void)testInsertionsLCS
{
    [self runInsertionsTestWithAlgorithm:HUBDiffLCSAlgorithm];
}

- (void)runInsertionsTestWithAlgorithm:(HUBDiffAlgorithm)algorithm
{
    id<HUBViewModel> firstViewModel = [self createViewModelWithIdentifier:@"Test"
                                                               components:@[]];
    NSArray<id<HUBComponentModel>> *secondComponents = @[
        [self createComponentModelWithIdentifier:@"component-1" customData:nil],
        [self createComponentModelWithIdentifier:@"component-2" customData:nil],
        [self createComponentModelWithIdentifier:@"component-3" customData:nil],
        [self createComponentModelWithIdentifier:@"component-4" customData:nil]
    ];
    id<HUBViewModel> secondViewModel = [self createViewModelWithIdentifier:@"Test"
                                                                components:secondComponents];

    HUBViewModelDiff *diff = [HUBViewModelDiff diffFromViewModel:firstViewModel toViewModel:secondViewModel algorithm:algorithm];
    XCTAssert([diff.insertedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:0 inSection:0]]);
    XCTAssert([diff.insertedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:1 inSection:0]]);
    XCTAssert([diff.insertedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:2 inSection:0]]);
    XCTAssert([diff.insertedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:3 inSection:0]]);
    XCTAssert(diff.reloadedBodyComponentIndexPaths.count == 0);
    XCTAssert(diff.insertedBodyComponentIndexPaths.count == 4);
    XCTAssert(diff.deletedBodyComponentIndexPaths.count == 0);
}

- (void)testReloadsMyers
{
    [self runReloadsTestWithAlgorithm:HUBDiffMyersAlgorithm];
}

- (void)testReloadsLCS
{
    [self runReloadsTestWithAlgorithm:HUBDiffLCSAlgorithm];
}

- (void)runReloadsTestWithAlgorithm:(HUBDiffAlgorithm)algorithm
{
    NSArray<id<HUBComponentModel>> *firstComponents = @[
        [self createComponentModelWithIdentifier:@"component-1" customData:nil],
        [self createComponentModelWithIdentifier:@"component-2" customData:nil],
        [self createComponentModelWithIdentifier:@"component-3" customData:nil],
        [self createComponentModelWithIdentifier:@"component-4" customData:nil]
    ];
    id<HUBViewModel> firstViewModel = [self createViewModelWithIdentifier:@"Test"
                                                            components:firstComponents];
    NSArray<id<HUBComponentModel>> *secondComponents = @[
        [self createComponentModelWithIdentifier:@"component-1" customData:@{@"test": @5}],
        [self createComponentModelWithIdentifier:@"component-2" customData:nil],
        [self createComponentModelWithIdentifier:@"component-3" customData:@{@"test": @6}],
        [self createComponentModelWithIdentifier:@"component-4" customData:nil]
    ];
    id<HUBViewModel> secondViewModel = [self createViewModelWithIdentifier:@"Test"
                                                                components:secondComponents];

    HUBViewModelDiff *diff = [HUBViewModelDiff diffFromViewModel:firstViewModel toViewModel:secondViewModel algorithm:algorithm];
    XCTAssert([diff.reloadedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:0 inSection:0]]);
    XCTAssert([diff.reloadedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:2 inSection:0]]);

    XCTAssert(diff.reloadedBodyComponentIndexPaths.count == 2);
    XCTAssert(diff.insertedBodyComponentIndexPaths.count == 0);
    XCTAssert(diff.deletedBodyComponentIndexPaths.count == 0);
}

- (void)testDeletionsMyers
{
    [self runDeletionsTestWithAlgorithm:HUBDiffMyersAlgorithm];
}

- (void)testDeletionsLCS
{
    [self runDeletionsTestWithAlgorithm:HUBDiffLCSAlgorithm];
}

- (void)runDeletionsTestWithAlgorithm:(HUBDiffAlgorithm)algorithm
{
    NSArray<id<HUBComponentModel>> *firstComponents = @[
        [self createComponentModelWithIdentifier:@"component-1" customData:nil],
        [self createComponentModelWithIdentifier:@"component-2" customData:nil],
        [self createComponentModelWithIdentifier:@"component-3" customData:nil],
        [self createComponentModelWithIdentifier:@"component-4" customData:nil]
    ];
    id<HUBViewModel> firstViewModel = [self createViewModelWithIdentifier:@"Test"
                                                            components:firstComponents];
    NSArray<id<HUBComponentModel>> *secondComponents = @[
        [self createComponentModelWithIdentifier:@"component-2" customData:nil],
        [self createComponentModelWithIdentifier:@"component-4" customData:nil]
    ];
    id<HUBViewModel> secondViewModel = [self createViewModelWithIdentifier:@"Test"
                                                                components:secondComponents];

    HUBViewModelDiff *diff = [HUBViewModelDiff diffFromViewModel:firstViewModel toViewModel:secondViewModel algorithm:algorithm];
    XCTAssert([diff.deletedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:0 inSection:0]]);
    XCTAssert([diff.deletedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:2 inSection:0]]);
    XCTAssert(diff.reloadedBodyComponentIndexPaths.count == 0);
    XCTAssert(diff.insertedBodyComponentIndexPaths.count == 0);
    XCTAssert(diff.deletedBodyComponentIndexPaths.count == 2);
}

- (void)testComplexChangeSetMyers
{
    [self runComplextChangeSetTestWithAlgorithm:HUBDiffMyersAlgorithm];
}

- (void)testComplexChangeSetLCS
{
    [self runComplextChangeSetTestWithAlgorithm:HUBDiffLCSAlgorithm];
}

- (void)runComplextChangeSetTestWithAlgorithm:(HUBDiffAlgorithm)algorithm
{
    NSArray<id<HUBComponentModel>> *firstComponents = @[
        [self createComponentModelWithIdentifier:@"component-1" customData:nil],
        [self createComponentModelWithIdentifier:@"component-2" customData:nil],
        [self createComponentModelWithIdentifier:@"component-3" customData:nil],
        [self createComponentModelWithIdentifier:@"component-4" customData:nil],
        [self createComponentModelWithIdentifier:@"component-5" customData:nil],
        [self createComponentModelWithIdentifier:@"component-6" customData:nil],
        [self createComponentModelWithIdentifier:@"component-7" customData:nil],
        [self createComponentModelWithIdentifier:@"component-8" customData:nil],
        [self createComponentModelWithIdentifier:@"component-9" customData:nil],
        [self createComponentModelWithIdentifier:@"component-10" customData:nil]
    ];
    id<HUBViewModel> firstViewModel = [self createViewModelWithIdentifier:@"Test"
                                                               components:firstComponents];
    NSArray<id<HUBComponentModel>> *secondComponents = @[
        [self createComponentModelWithIdentifier:@"component-1" customData:nil],
        [self createComponentModelWithIdentifier:@"component-2" customData:@{@"test": @1}],
        [self createComponentModelWithIdentifier:@"component-30" customData:nil],
        [self createComponentModelWithIdentifier:@"component-4" customData:nil],
        [self createComponentModelWithIdentifier:@"component-5" customData:nil],
        [self createComponentModelWithIdentifier:@"component-6" customData:nil],
        [self createComponentModelWithIdentifier:@"component-7" customData:nil],
        [self createComponentModelWithIdentifier:@"component-9" customData:@{@"test": @2}],
        [self createComponentModelWithIdentifier:@"component-10" customData:nil],
        [self createComponentModelWithIdentifier:@"component-13" customData:nil]
    ];
    id<HUBViewModel> secondViewModel = [self createViewModelWithIdentifier:@"Test"
                                                                components:secondComponents];

    HUBViewModelDiff *diff = [HUBViewModelDiff diffFromViewModel:firstViewModel toViewModel:secondViewModel algorithm:algorithm];
    XCTAssert([diff.deletedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:2 inSection:0]]);
    XCTAssert([diff.deletedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:7 inSection:0]]);
    XCTAssert([diff.insertedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:2 inSection:0]]);
    XCTAssert([diff.insertedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:9 inSection:0]]);
    XCTAssert([diff.reloadedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:1 inSection:0]]);
    XCTAssert([diff.reloadedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:8 inSection:0]]);
    XCTAssert(diff.reloadedBodyComponentIndexPaths.count == 2);
    XCTAssert(diff.insertedBodyComponentIndexPaths.count == 2);
    XCTAssert(diff.deletedBodyComponentIndexPaths.count == 2);
}

- (void)testInsertionOfSingleComponentModelAtStartWithDataChangesMyers
{
    [self runInsertionOfSingleComponentModelAtStartWithDataChangesTestWithAlgorithm:HUBDiffMyersAlgorithm];
}

- (void)testInsertionOfSingleComponentModelAtStartWithDataChangesLCS
{
    [self runInsertionOfSingleComponentModelAtStartWithDataChangesTestWithAlgorithm:HUBDiffLCSAlgorithm];
}

- (void)runInsertionOfSingleComponentModelAtStartWithDataChangesTestWithAlgorithm:(HUBDiffAlgorithm)algorithm
{
    NSArray<id<HUBComponentModel>> *firstComponents = @[
        [self createComponentModelWithIdentifier:@"component-1" customData:nil],
        [self createComponentModelWithIdentifier:@"component-2" customData:nil],
        [self createComponentModelWithIdentifier:@"component-3" customData:nil]
    ];
    id<HUBViewModel> firstViewModel = [self createViewModelWithIdentifier:@"Test"
                                                               components:firstComponents];
    NSArray<id<HUBComponentModel>> *secondComponents = @[
        [self createComponentModelWithIdentifier:@"component-0" customData:nil],
        [self createComponentModelWithIdentifier:@"component-1" customData:@{@"test": @1}],
        [self createComponentModelWithIdentifier:@"component-2" customData:@{@"test": @1}],
        [self createComponentModelWithIdentifier:@"component-3" customData:@{@"test": @1}]
    ];
    id<HUBViewModel> secondViewModel = [self createViewModelWithIdentifier:@"Test"
                                                                components:secondComponents];

    HUBViewModelDiff *diff = [HUBViewModelDiff diffFromViewModel:firstViewModel toViewModel:secondViewModel algorithm:algorithm];
    XCTAssert(diff.reloadedBodyComponentIndexPaths.count == 3);
    XCTAssert(diff.insertedBodyComponentIndexPaths.count == 1);
    XCTAssert(diff.deletedBodyComponentIndexPaths.count == 0);
    XCTAssert([diff.insertedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:0 inSection:0]]);
    XCTAssert([diff.reloadedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:0 inSection:0]]);
    XCTAssert([diff.reloadedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:1 inSection:0]]);
    XCTAssert([diff.reloadedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:2 inSection:0]]);
}

- (void)testInsertionOfMultipleComponentModelsAtStartWithDataChangesMyers
{
    [self runInsertionOfMultipleComponentModelsAtStartWithDataChangesTestWithAlgorithm:HUBDiffMyersAlgorithm];
}

- (void)testInsertionOfMultipleComponentModelsAtStartWithDataChangesLCS
{
    [self runInsertionOfMultipleComponentModelsAtStartWithDataChangesTestWithAlgorithm:HUBDiffLCSAlgorithm];
}

- (void)runInsertionOfMultipleComponentModelsAtStartWithDataChangesTestWithAlgorithm:(HUBDiffAlgorithm)algorithm
{
    NSArray<id<HUBComponentModel>> *firstComponents = @[
        [self createComponentModelWithIdentifier:@"component-1" customData:nil],
        [self createComponentModelWithIdentifier:@"component-2" customData:nil],
        [self createComponentModelWithIdentifier:@"component-3" customData:nil]
    ];
    id<HUBViewModel> firstViewModel = [self createViewModelWithIdentifier:@"Test"
                                                               components:firstComponents];
    NSArray<id<HUBComponentModel>> *secondComponents = @[
        [self createComponentModelWithIdentifier:@"component-0" customData:nil],
        [self createComponentModelWithIdentifier:@"component-00" customData:nil],
        [self createComponentModelWithIdentifier:@"component-1" customData:@{@"test": @1}],
        [self createComponentModelWithIdentifier:@"component-2" customData:@{@"test": @1}],
        [self createComponentModelWithIdentifier:@"component-3" customData:@{@"test": @1}]
    ];
    id<HUBViewModel> secondViewModel = [self createViewModelWithIdentifier:@"Test"
                                                                components:secondComponents];

    HUBViewModelDiff *diff = [HUBViewModelDiff diffFromViewModel:firstViewModel toViewModel:secondViewModel algorithm:algorithm];
    XCTAssert(diff.reloadedBodyComponentIndexPaths.count == 3);
    XCTAssert(diff.insertedBodyComponentIndexPaths.count == 2);
    XCTAssert(diff.deletedBodyComponentIndexPaths.count == 0);
    XCTAssert([diff.insertedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:0 inSection:0]]);
    XCTAssert([diff.insertedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:1 inSection:0]]);
    XCTAssert([diff.reloadedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:0 inSection:0]]);
    XCTAssert([diff.reloadedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:1 inSection:0]]);
    XCTAssert([diff.reloadedBodyComponentIndexPaths containsObject:[NSIndexPath indexPathForItem:2 inSection:0]]);
}

@end
