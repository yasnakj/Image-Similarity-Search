#lang racket

;; Function to read a histogram from a file and convert it into a list
(define (read-histogram filename)
  (with-input-from-file filename
    (lambda ()
      (let loop ((line (read-line)) (hist '()))
        (if (eof-object? line)
            (reverse hist)
            (loop (read-line) (append hist (map string->number (string-split line)))))))))

;; Function to compute the histogram intersection between two histograms
(define (histogram-intersection hist1 hist2)
  (foldl (lambda (x y acc) (+ acc (min x y))) 0 (map list hist1 hist2)))

;; Function to normalize a histogram by dividing each value by the sum of all values
(define (normalize-histogram hist)
  (let ((sum (apply + hist)))
    (map (lambda (x) (/ x sum)) hist)))

;; Function to compare two normalized histograms and return their similarity
(define (compare-histograms hist1 hist2)
  (histogram-intersection (normalize-histogram hist1) (normalize-histogram hist2)))

;; Main function that finds the 5 most similar images to the query image
(define (similarity-search query-histogram-filename image-dataset-directory)
  (let ((query-hist (read-histogram query-histogram-filename))
        (image-files (directory-list image-dataset-directory)))
    (let ((scores (map (lambda (file)
                         (let ((hist (read-histogram (build-path image-dataset-directory file))))
                           (cons file (compare-histograms query-hist hist))))
                       image-files)))
      (map car (take (sort scores (lambda (a b) (> (cdr a) (cdr b)))) 5)))))

;; (similarity-search "path/to/query/histogram.txt" "path/to/image/dataset/directory")

