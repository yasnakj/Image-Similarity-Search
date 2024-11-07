package main

import (
	"fmt"
	"image"
	_ "image/jpeg"
	"math"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// Histo holds the histogram and the name of the image.
type Histo struct {
	Name string
	H    []float64
}

// computeHistogram computes the histogram of a given image.
func computeHistogram(imagePath string, depth int) (Histo, error) {
	file, err := os.Open(imagePath)
	if err != nil {
		return Histo{}, err
	}
	defer file.Close()

	img, _, err := image.Decode(file)
	if err != nil {
		return Histo{}, err
	}

	histo := Histo{
		Name: filepath.Base(imagePath),
		H:    make([]float64, 1<<(3*depth)),
	}

	bounds := img.Bounds()
	for y := bounds.Min.Y; y < bounds.Max.Y; y++ {
		for x := bounds.Min.X; x < bounds.Max.X; x++ {
			r, g, b, _ := img.At(x, y).RGBA()
			r, g, b = r>>8, g>>8, b>>8
			index := (((r >> (8 - depth)) << (2 * depth)) + ((g >> (8 - depth)) << depth) + (b >> (8 - depth)))
			histo.H[index]++
		}
	}

	// Normalize histogram
	totalPixels := float64(bounds.Dx() * bounds.Dy())
	for i := range histo.H {
		histo.H[i] = float64(histo.H[i]) / totalPixels
	}

	return histo, nil
}

// computeHistograms computes histograms for a slice of images and sends them over a channel.
func computeHistograms(imagePaths []string, depth int, hChan chan<- Histo, wg *sync.WaitGroup) {
	defer wg.Done()
	for _, path := range imagePaths {
		histo, err := computeHistogram(path, depth)
		if err != nil {
			fmt.Printf("Error computing histogram for %s: %v\n", path, err)
			continue
		}
		hChan <- histo
	}

}

// SimilarImage holds the similarity information between two images.
type SimilarImage struct {
	Name       string
	Similarity float64
}

// histogramSimilarity calculates the similarity between two histograms.
func histogramSimilarity(h1, h2 []float64) float64 {
	var intersection float64
	for i := range h1 {
		intersection += math.Min(h1[i], h2[i]) // Both h1 and h2 are of type []float64
	}
	return intersection
}

// insertSorted inserts a SimilarImage into a sorted slice of SimilarImages, keeping the top 5.
func insertSorted(similarImages []SimilarImage, newImage SimilarImage) []SimilarImage {
	index := 0
	for ; index < len(similarImages); index++ {
		if newImage.Similarity > similarImages[index].Similarity {
			break
		}
	}
	if index == 5 { // New image is not in the top 5
		return similarImages
	}
	similarImages = append(similarImages[:index], append([]SimilarImage{newImage}, similarImages[index:]...)...)
	if len(similarImages) > 5 {
		similarImages = similarImages[:5] // Keep only the top 5
	}
	return similarImages
}

func main() {
	startTime := time.Now()

	if len(os.Args) < 3 {
		fmt.Println("Usage: go run similaritySearch.go <queryImageFilename> <imageDatasetDirectory>")
		return
	}

	queryImageFilename := os.Args[1]
	imageDatasetDirectory := os.Args[2]

	queryHisto, err := computeHistogram(queryImageFilename, 3)
	if err != nil {
		fmt.Printf("Failed to compute histogram for query image: %v\n", err)
		return
	}

	files, err := filepath.Glob(filepath.Join(imageDatasetDirectory, "*.jpg"))
	if err != nil {
		fmt.Printf("Failed to list dataset images: %v\n", err)
		return
	}

	hChan := make(chan Histo)
	var wg sync.WaitGroup

	K := 64 // Adjust based on experimentations
	partitionSize := len(files) / K
	for i := 0; i < K; i++ {
		start := i * partitionSize
		end := start + partitionSize
		if i == K-1 {
			end = len(files)
		}
		wg.Add(1)
		go computeHistograms(files[start:end], 3, hChan, &wg)
	}

	go func() {
		wg.Wait()
		close(hChan)
	}()

	var mostSimilar []SimilarImage
	for histo := range hChan {
		similarity := histogramSimilarity(queryHisto.H, histo.H)
		mostSimilar = insertSorted(mostSimilar, SimilarImage{Name: histo.Name, Similarity: similarity})
	}

	// fmt.Println("Most similar images:")
	// for _, img := range mostSimilar {
	//	fmt.Printf("%s (Similarity: %f)\n", img.Name, img.Similarity)
	// }

	endTime := time.Now()
	fmt.Printf("Execution Time: %v\n", endTime.Sub(startTime))
}
