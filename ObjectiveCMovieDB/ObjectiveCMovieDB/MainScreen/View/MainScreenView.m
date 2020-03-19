//
//  MainScreenView.m
//  ObjectiveCMovieDB
//
//  Created by Henrique Figueiredo Conte on 16/03/20.
//  Copyright © 2020 Henrique Figueiredo Conte. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MainScreenView.h"
#import "MoviesTableCell.h"
#import "MainScreenNetwork.h"
#import "MoviesList.h"


@interface MainScreenView ()

@property(nonatomic, readwrite, assign) BOOL prefersLargeTitle;

@end


@implementation MainScreenView

@synthesize moviesTableView = _moviesTableView;
@synthesize moviesSearchBar = _moviesSearchBar;

MainScreenNetwork *network = nil;
NSMutableArray<MainScreenMovie*> *popularMovies = nil;
NSMutableArray<MainScreenMovie*> *playingNowMovies = nil;

- (void) viewDidLoad {
    [super viewDidLoad];

    _moviesTableView.delegate = self;
    _moviesTableView.dataSource = self;
    _moviesTableView.sectionHeaderHeight = 50;
    
    [self setNavigationBar];
    
    popularMovies = NSMutableArray.new;
    playingNowMovies = NSMutableArray.new;
    network = MainScreenNetwork.instantiateNetwork;
    
    [network getDataFrom:@"https://api.themoviedb.org/3/movie/popular?page=1&language=en-US&api_key=77d63fcdb563d7f208a22cca549b5f3e" completion:^ (NSMutableArray * moviesList) {
        
        popularMovies = [[NSMutableArray alloc] initWithArray:moviesList];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_moviesTableView reloadData];
        });
        
    }];
    
    [network getDataFrom:@"https://api.themoviedb.org/3/movie/now_playing?api_key=77d63fcdb563d7f208a22cca549b5f3e&language=en-US&page=1" completion:^ (NSMutableArray * moviesList) {
        
        playingNowMovies = [[NSMutableArray alloc] initWithArray:moviesList];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_moviesTableView reloadData];
        });
        
    }];
}

- (void) setNavigationBar {
    
    self.title = @"Movies";
    
    self.navigationController.navigationBar.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
}
 
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    MoviesTableCell *cell = (MoviesTableCell *)[tableView dequeueReusableCellWithIdentifier:@"movieCell"];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"movieCell" owner:self options:nil];
        cell = [nib objectAtIndex: 0];
    }
    
    MainScreenMovie *newMovie = [[MainScreenMovie alloc] init];
    
    if ([indexPath section] == 0) {
        newMovie = [popularMovies objectAtIndex: [indexPath row]];
    }
    else if ([indexPath section] == 1) {
        newMovie = [playingNowMovies objectAtIndex: [indexPath row]];
    }
    
    NSNumber *voteAverage = [newMovie voteAverage];
    NSString *posterPath = [newMovie posterPath];
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle: NSNumberFormatterDecimalStyle];
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = 2;
    [formatter setRoundingMode:NSNumberFormatterRoundFloor];
    NSString* ratingString = [formatter stringFromNumber:[NSNumber numberWithFloat:[voteAverage floatValue]]];
    
    
    NSString *urlString = [NSString stringWithFormat: @"%s%@", "https://image.tmdb.org/t/p/w500", posterPath];
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *posterImageData = [[NSData alloc] initWithContentsOfURL: url];
    
    [[cell movieImage] setImage: [UIImage imageWithData: posterImageData]];
    [[[cell movieImage] layer] setCornerRadius: 10];
    
    [[cell movieTitleLabel] setText: [newMovie title]];

    [[cell movieDescriptionLabel] setText: [newMovie overview]];
    
    [[cell movieRatingLabel] setText: ratingString];

    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return [popularMovies count];
    }
    else if (section == 1) {
        return [playingNowMovies count];
    }
    
    else {
        return 0;
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *sectionView =  [[UIView alloc] initWithFrame:CGRectMake(0, 0, _moviesTableView.frame.size.width, 20)];
    
    UILabel *sectionLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, _moviesTableView.frame.size.width, 25)];
    
    NSString *title = @"Others";
    
    [sectionLabel setFont: [UIFont boldSystemFontOfSize:20]];
    
    [sectionView addSubview: sectionLabel];
    [sectionView setBackgroundColor: [UIColor whiteColor]];
    
    if (section == 0) {
         title = @"Popular Movies";
    }
    
    else if (section == 1) {
         title = @"Playing Now";
    }
    
    [sectionLabel setText: title];
    
    return sectionView;
}

@end

