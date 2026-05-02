package components

import (
	"TaipeiCityDashboardBE/logs"
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// VectorClient handles communication with Qdrant vector database
type VectorClient struct {
	baseURL    string
	apiKey     string
	collection string
	client     *http.Client
}

// QdrantPoint represents a point to be upserted into Qdrant
type QdrantPoint struct {
	ID      string                 `json:"id"`
	Vector  []float64              `json:"vector"`
	Payload map[string]interface{} `json:"payload"`
}

// NewVectorClient creates a new Qdrant vector client
func NewVectorClient(baseURL, apiKey, collection string) *VectorClient {
	return &VectorClient{
		baseURL:    baseURL,
		apiKey:     apiKey,
		collection: collection,
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// UpsertPoint adds or updates a point in the Qdrant collection
func (vc *VectorClient) UpsertPoint(id, text string, payload map[string]interface{}) error {
	// Generate embedding for the text
	vector, err := vc.generateEmbedding(text)
	if err != nil {
		return fmt.Errorf("failed to generate embedding: %v", err)
	}

	point := QdrantPoint{
		ID:      id,
		Vector:  vector,
		Payload: payload,
	}

	// Create request body
	requestBody := map[string]interface{}{
		"points": []QdrantPoint{point},
	}

	jsonBody, err := json.Marshal(requestBody)
	if err != nil {
		return err
	}

	// Send request to Qdrant
	url := fmt.Sprintf("%s/collections/%s/points?wait=true", vc.baseURL, vc.collection)
	req, err := http.NewRequest("PUT", url, bytes.NewBuffer(jsonBody))
	if err != nil {
		return err
	}

	req.Header.Set("Content-Type", "application/json")
	if vc.apiKey != "" {
		req.Header.Set("api-key", vc.apiKey)
	}

	resp, err := vc.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("Qdrant error %d: %s", resp.StatusCode, string(body))
	}

	return nil
}

// SearchPoints searches for points similar to the query text
func (vc *VectorClient) SearchPoints(query string, limit int, scoreThreshold float64) ([]map[string]interface{}, error) {
	// Generate embedding for the query
	vector, err := vc.generateEmbedding(query)
	if err != nil {
		return nil, fmt.Errorf("failed to generate embedding: %v", err)
	}

	searchRequest := map[string]interface{}{
		"vector":              vector,
		"limit":               limit,
		"score_threshold":     scoreThreshold,
		"with_payload":        true,
		"with_vectors":        false,
	}

	jsonBody, err := json.Marshal(searchRequest)
	if err != nil {
		return nil, err
	}

	// Send request to Qdrant
	url := fmt.Sprintf("%s/collections/%s/points/search", vc.baseURL, vc.collection)
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonBody))
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", "application/json")
	if vc.apiKey != "" {
		req.Header.Set("api-key", vc.apiKey)
	}

	resp, err := vc.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("Qdrant error %d: %s", resp.StatusCode, string(body))
	}

	var result struct {
		Result []struct {
			ID      string                 `json:"id"`
			Score   float64                `json:"score"`
			Payload map[string]interface{} `json:"payload"`
		} `json:"result"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	// Convert to output format
	output := make([]map[string]interface{}, 0, len(result.Result))
	for _, item := range result.Result {
		output = append(output, map[string]interface{}{
			"id":      item.ID,
			"score":   item.Score,
			"payload": item.Payload,
		})
	}

	return output, nil
}

// generateEmbedding creates a vector embedding for text
// Uses the existing Qdrant embedding models or external API
func (vc *VectorClient) generateEmbedding(text string) ([]float64, error) {
	// Check if we have local embedding capability
	// For now, use a simple hash-based approach or call external API
	// In production, integrate with ONNX or sentence-transformers

	// Placeholder: Call external embedding API or use local model
	// For MVP, return a dummy vector (will be replaced with real embedding)
	return vc.callEmbeddingAPI(text)
}

// callEmbeddingAPI calls the embedding API (using Qdrant's built-in or external service)
func (vc *VectorClient) callEmbeddingAPI(text string) ([]float64, error) {
	// Use Qdrant's built-in text embedding (if configured)
	// Or call an external embedding service

	// For MVP: Create a dummy vector based on text hash
	// Production should use: OpenAI, Ollama, ONNX models, etc.
	
	vector := make([]float64, 384) // Default 384 dimensions for ONNX models
	
	// Simple hash-based vector generation (for MVP only)
	hash := 0
	for _, c := range text {
		hash = ((hash << 5) - hash) + int(c)
	}

	// Fill vector with pseudo-random values based on hash
	for i := 0; i < len(vector); i++ {
		val := float64((hash*i+i)%1000) / 1000.0
		vector[i] = val * 2.0 - 1.0 // Normalize to [-1, 1]
	}

	return vector, nil
}

// EnsureCollection creates the components collection in Qdrant if it doesn't exist
func (vc *VectorClient) EnsureCollection() error {
	logs.FInfo("Ensuring Qdrant collection '%s' exists", vc.collection)

	// Check if collection exists
	url := fmt.Sprintf("%s/collections/%s", vc.baseURL, vc.collection)
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return err
	}

	if vc.apiKey != "" {
		req.Header.Set("api-key", vc.apiKey)
	}

	resp, err := vc.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode == 200 {
		logs.FInfo("Collection '%s' already exists", vc.collection)
		return nil
	}

	// Create collection if it doesn't exist
	logs.FInfo("Creating collection '%s'", vc.collection)

	createRequest := map[string]interface{}{
		"vectors": map[string]interface{}{
			"size":       384,
			"distance":   "Cosine",
		},
	}

	jsonBody, err := json.Marshal(createRequest)
	if err != nil {
		return err
	}

	url = fmt.Sprintf("%s/collections/%s", vc.baseURL, vc.collection)
	req, err = http.NewRequest("PUT", url, bytes.NewBuffer(jsonBody))
	if err != nil {
		return err
	}

	req.Header.Set("Content-Type", "application/json")
	if vc.apiKey != "" {
		req.Header.Set("api-key", vc.apiKey)
	}

	resp, err = vc.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("failed to create collection: %d %s", resp.StatusCode, string(body))
	}

	logs.FInfo("Collection '%s' created successfully", vc.collection)
	return nil
}
