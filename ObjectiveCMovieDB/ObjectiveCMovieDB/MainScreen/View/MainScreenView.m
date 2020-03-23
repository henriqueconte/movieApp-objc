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
#import "MovieDetailsViewController.h"


@interface MainScreenView ()

@property(nonatomic, readwrite, assign) BOOL prefersLargeTitle;
@property(nonatomic) int selectedMovieID;
@property(nonatomic) BOOL isSearchActive;

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
    
    _moviesSearchBar.delegate = self;
    
    [self setNavigationBar];
    
    popularMovies = NSMutableArray.new;
    playingNowMovies = NSMutableArray.new;
    network = MainScreenNetwork.instantiateNetwork;
    
    self.isSearchActive = false;
    
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"toMovieDetailsScreen"])
    {
        // Get reference to the destination view controller
        MovieDetailsViewController *vc = segue.destinationViewController;

        // Pass any objects to the view controller here, like...
        vc.movieId = self.selectedMovieID;
    }
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
    else if ([indexPath section] == 1 && self.isSearchActive == false) {
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
    
    cell.movieId = [newMovie movieId];
    
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
    else {
        return section == 1 && self.isSearchActive == false ? [playingNowMovies count] : 0;
    }

}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.isSearchActive == false ? 2 : 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
      return 50.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *sectionView =  [[UIView alloc] initWithFrame:CGRectMake(0, 0, _moviesTableView.frame.size.width, 20)];
    
    UILabel *sectionLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, _moviesTableView.frame.size.width, 25)];
    
    NSString *title = @"";
    
    [sectionLabel setFont: [UIFont boldSystemFontOfSize:20]];
    
    [sectionView addSubview: sectionLabel];
    [sectionView setBackgroundColor: [UIColor whiteColor]];
    
    if (section == 0) {
        if(self.isSearchActive == false) {
            title = @"Popular Movies";
        } else {
            title = @"Search Results";
        }
    }
    
    else if (section == 1 && self.isSearchActive == false) {
         title = @"Playing Now";
    }
    
    [sectionLabel setText: title];
    
    return sectionView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 60.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 50)];
    UIButton *showMoreButton=[UIButton buttonWithType:UIButtonTypeCustom];
    [showMoreButton setTitle:@"Show more" forState:UIControlStateNormal];
    
    if(section == 0) {
    [showMoreButton addTarget:self action:@selector(showMorePopularMoviesButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    else if(section == 1) {
        [showMoreButton addTarget:self action:@selector(showMoreNowPlayingMoviesButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [showMoreButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    showMoreButton.frame=CGRectMake(0, 0, 130, 30);
    showMoreButton.center = footerView.center;
    
    showMoreButton.clipsToBounds = YES;
    showMoreButton.layer.cornerRadius = 10.0f;
    showMoreButton.layer.borderColor = [UIColor blackColor].CGColor;
    showMoreButton.layer.borderWidth = 2.0f;
    
    [footerView addSubview:showMoreButton];
    return footerView;
}

- (void)showMorePopularMoviesButton:(id)sender
{
    NSLog(@"Hello button");
}

- (void)showMoreNowPlayingMoviesButton:(id)sender
{
    NSLog(@"Hello button 2");
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MainScreenMovie *selectedMovie = nil;
    
    if (indexPath.section == 0) {
         selectedMovie = [popularMovies objectAtIndex: [indexPath row]];
    }
    
    else if (indexPath.section == 1) {
        selectedMovie = [playingNowMovies objectAtIndex: [indexPath row]];
    }
    NSNumber *movieIdNumber = [selectedMovie movieId];
    self.selectedMovieID = [movieIdNumber intValue];
    
    [self performSegueWithIdentifier:@"toMovieDetailsScreen" sender:nil];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    
    if(![searchText  isEqual: @""]) {
        self.isSearchActive = true;
        NSString *searchUrlString = [NSString stringWithFormat: @"%s%@", "https://api.themoviedb.org/3/search/movie?api_key=fb61737ab2cdee1c07a947778f249e7d&query=", searchText];
        [network getDataFrom:searchUrlString completion:^ (NSMutableArray * moviesList) {
            popularMovies = [[NSMutableArray alloc] initWithArray:moviesList];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_moviesTableView reloadData];
            });
        }];
    } else {
        self.isSearchActive = false;
        
        [network getDataFrom:@"https://api.themoviedb.org/3/movie/popular?page=1&language=en-US&api_key=77d63fcdb563d7f208a22cca549b5f3e" completion:^ (NSMutableArray * moviesList) {
            
            popularMovies = [[NSMutableArray alloc] initWithArray:moviesList];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_moviesTableView reloadData];
            });
        }];
    }
}

@end

