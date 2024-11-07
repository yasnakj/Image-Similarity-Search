% dataset(DirectoryName)
% this is where the image dataset is located
dataset('/Users/yasna/Desktop/part4/imageDataset2_15_20/').

% Defines where the query images are located.
query_images_directory('/Users/yasna/Desktop/part4/queryImages/').

% directory_textfiles(DirectoryName, ListOfTextfiles)
% produces the list of text files in a directory
directory_textfiles(D,Textfiles):- directory_files(D,Files), include(isTextFile, Files, Textfiles).
isTextFile(Filename):-string_concat(_,'.txt',Filename).

% read_hist_file(Filename,ListOfNumbers)
% reads a histogram file and produces a list of numbers (bin values)
read_hist_file(Filename,Numbers):- open(Filename,read,Stream),read_line_to_string(Stream,_),
                                   read_line_to_string(Stream,String), close(Stream),
								   atomic_list_concat(List, ' ', String),atoms_numbers(List,Numbers).
								   
% similarity_search(QueryFile,SimilarImageList)
% returns the list of images similar to the query image
% similar images are specified as (ImageName, SimilarityScore)
% predicat dataset/1 provides the location of the image set
similarity_search(QueryFile, SimilarList) :-
    dataset(DatasetDir),
    directory_textfiles(DatasetDir, DatasetFiles),  % Get list of dataset files
    query_images_directory(QueryDir),               % Define the query directory
    atom_concat(QueryDir, QueryFile, FullQueryPath),% Construct the full query file path
    read_hist_file(FullQueryPath, QueryHisto),     % Read the query histogram file
    compare_histograms(QueryHisto, DatasetDir, DatasetFiles, Scores), % Compare histograms
    sort(2, @>, Scores, Sorted),                    % Sort the scores
    take(Sorted, 5, SimilarList).                   % Take the top 5 results
											
% similarity_search(QueryFile, DatasetDirectory, HistoFileList, SimilarImageList)
similarity_search(QueryFile,DatasetDirectory, DatasetFiles,Best):- read_hist_file(QueryFile,QueryHisto), 
                                            compare_histograms(QueryHisto, DatasetDirectory, DatasetFiles, Scores), 
                                            sort(2,@>,Scores,Sorted),take(Sorted,5,Best).

% compare_histograms(QueryHisto,DatasetDirectory,DatasetFiles,Scores)
% compares a query histogram with a list of histogram files 
compare_histograms(QueryHisto, DatasetDirectory, DatasetFiles, Scores) :-
    maplist(compare_histogram_with_query(QueryHisto, DatasetDirectory), DatasetFiles, Scores).

compare_histogram_with_query(QueryHisto, DatasetDirectory, File, (File, Score)) :-
    atom_concat(DatasetDirectory, File, Path),
    read_hist_file(Path, Histo),
    histogram_intersection(QueryHisto, Histo, Score).



% histogram_intersection(Histogram1, Histogram2, Score)
% compute the intersection similarity score between two histograms
% Score is between 0.0 and 1.0 (1.0 for identical histograms)
% Define min/3 predicate to find the minimum of two numbers.
min(X, Y, Min) :-
    (X < Y -> Min = X ; Min = Y).
histogram_intersection(H1, H2, Score) :-
    maplist(min, H1, H2, Mins),  % Find the minimum of corresponding elements
    sum_list(Mins, Sum),         % Sum up the minima
    sum_list(H1, SumH1),         % Sum up the elements in the first histogram
    Score is Sum / SumH1.        % Compute the score as the ratio of the sums

% take(List,K,KList)
% extracts the K first items in a list
take(Src,N,L) :- findall(E, (nth1(I,Src,E), I =< N), L).
% atoms_numbers(ListOfAtoms,ListOfNumbers)
% converts a list of atoms into a list of numbers
atoms_numbers([],[]).
atoms_numbers([X|L],[Y|T]):- atom_number(X,Y), atoms_numbers(L,T).
atoms_numbers([X|L],T):- \+atom_number(X,_), atoms_numbers(L,T).
