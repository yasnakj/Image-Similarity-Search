% dataset(DirectoryName)
% this is where the image dataset is located
dataset('C:/Users/Michelle/Desktop/_winter24/CS12120/Project4/imageDataset2_15_20').
% directory_textfiles(DirectoryName, ListOfTextfiles)
% produces the list of text files in a directory
directory_textfiles(D,Textfiles):- directory_files(D,Files), include(isTextFile, Files, Textfiles).
isTextFile(Filename):-string_concat(_,'.txt',Filename).
% read_hist_file(Filename,ListOfNumbers)
% reads a histogram file and produces a list of numbers (bin values)
read_hist_file(Filename,Numbers):- open(Filename,read,Stream),read_line_to_string(Stream,_),
                                   read_line_to_string(Stream,String), close(Stream),
								   atomic_list_concat(List, ' ', String),atoms_numbers(List,Numbers).

% similarity_search('C:/Users/Michelle/Desktop/_winter24/CS12120/Project4/queryImages/q00.jpg.txt','C:/Users/Michelle/Desktop/_winter24/CS12120/Project4/imageDataset2_15_20'). 
% similarity_search(QueryFile,SimilarImageList)
% returns the list of images similar to the query image
% similar images are specified as (ImageName, SimilarityScore)
% predicat dataset/1 provides the location of the image set
similarity_search(QueryFile,SimilarList) :- dataset(D), directory_textfiles(D,TxtFiles),
                                            similarity_search(QueryFile,D,TxtFiles,SimilarList).
											
% similarity_search(QueryFile, DatasetDirectory, HistoFileList, SimilarImageList)
similarity_search(QueryFile,DatasetDirectory, DatasetFiles,Best):- read_hist_file(QueryFile,QueryHisto), 
                                            compare_histograms(QueryHisto, DatasetDirectory, DatasetFiles, Scores), 
                                            sort(2,@>,Scores,Sorted),take(Sorted,5,Best).


%read_hist_file(q00.jpg,ListOfNumbers).
 %similarity_search('C:/Users/Michelle/Desktop/_winter24/CS12120/Project4/queryImages/q00.jpg.txt', 'C:/Users/Michelle\Desktop/_winter24/CS12120/Project4/queryImages', HistoFileList, SimilarImageList).


% compare_histograms(QueryHisto,DatasetDirectory,DatasetFiles,Scores)
% compares a query histogram with a list of histogram files 
compare_histograms(_, _, [], []).
compare_histograms(QueryHisto, DatasetDirectory, [File|RestFiles], [(File, Score)|RestScores]) :-
    atomic_list_concat([DatasetDirectory, '/', File], FilePath),
    read_hist_file(FilePath, Hist),
    histogram_intersection(QueryHisto, Hist, Score),
    compare_histograms(QueryHisto, DatasetDirectory, RestFiles, RestScores).

% histogram_intersection(Histogram1, Histogram2, Score)
% compute the intersection similarity score between two histograms
% Score is between 0.0 and 1.0 (1.0 for identical histograms)


% histogram_intersection_with_normalization(Histogram1, Histogram2, Score)
% compute the intersection similarity score between two normalized histograms
% Score is between 0.0 and 1.0 (1.0 for identical histograms)
histogram_intersection_with_normalization(H1, H2, S) :-
    normalize_histogram(H1, NormalizedH1),
    normalize_histogram(H2, NormalizedH2),
    histogram_intersection(NormalizedH1, NormalizedH2, S).

% normalize_histogram(Histogram, NormalizedHistogram)
% normalize a histogram by dividing each bin value by the sum of all bin values
normalize_histogram(Histogram, NormalizedHistogram) :-
    sum_list(Histogram, Sum),
    maplist(divide(Sum), Histogram, NormalizedHistogram).

% divide(Divisor, Dividend, Result)
% divide Dividend by Divisor
divide(_, 0, 0). % Avoid division by zero
divide(Divisor, Dividend, Result) :-
    Result is Dividend / Divisor.

% histogram_intersection(Histogram1, Histogram2, Score)
% compute the intersection similarity score between two histograms
% Score is between 0.0 and 1.0 (1.0 for identical histograms)
histogram_intersection(H1, H2, S) :-
    sum_min(H1, H2, Intersection),
    sum_list(H1, Sum1),
    sum_list(H2, Sum2),
    S is Intersection / min(Sum1, Sum2).

% sum_min(List1, List2, Sum)
% sum the minimum value of each pair of elements in two lists
sum_min([], [], 0).
sum_min([H1|T1], [H2|T2], Sum) :-
    Min is min(H1, H2),
    sum_min(T1, T2, RestSum),
    Sum is Min + RestSum.

% Other predicates and utility functions remain the same
% take(List,K,KList)
% extracts the K first items in a list
take(Src,N,L) :- findall(E, (nth1(I,Src,E), I =< N), L).
% atoms_numbers(ListOfAtoms,ListOfNumbers)
% converts a list of atoms into a list of numbers
atoms_numbers([],[]).
atoms_numbers([X|L],[Y|T]):- atom_number(X,Y), atoms_numbers(L,T).
atoms_numbers([X|L],T):- \+atom_number(X,_), atoms_numbers(L,T).


