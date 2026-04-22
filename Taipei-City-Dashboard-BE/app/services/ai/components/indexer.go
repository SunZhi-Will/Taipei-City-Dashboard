package components

import (
	"TaipeiCityDashboardBE/logs"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

// ComponentMetadata represents the indexed component information
type ComponentMetadata struct {
	ID               string            `json:"id"`
	Name             string            `json:"name"`
	Path             string            `json:"path"`
	RelativePath     string            `json:"relative_path"`
	Category         string            `json:"category"`
	Description      string            `json:"description"`
	Purpose          []string          `json:"purpose"`
	Props            map[string]string `json:"props"`
	Tags             []string          `json:"tags"`
	Dependencies     []string          `json:"dependencies"`
	UsageExample     string            `json:"usage_example"`
	RelatedComponent []string          `json:"related_components"`
	IndexedAt        time.Time         `json:"indexed_at"`
}

// ComponentIndexer manages the indexing of Vue components
type ComponentIndexer struct {
	baseDir      string
	components   []ComponentMetadata
	vectorClient *VectorClient
}

// NewComponentIndexer creates a new component indexer
func NewComponentIndexer(baseDir string, vectorClient *VectorClient) *ComponentIndexer {
	return &ComponentIndexer{
		baseDir:      baseDir,
		components:   make([]ComponentMetadata, 0),
		vectorClient: vectorClient,
	}
}

// IndexComponents scans the frontend directory and indexes all Vue components
func (ci *ComponentIndexer) IndexComponents() error {
	logs.FInfo("Starting component indexing from: %s", ci.baseDir)

	// Scan directories
	componentPaths := make([]string, 0)

	// Target directories
	targetDirs := []string{
		filepath.Join(ci.baseDir, "src", "components"),
		filepath.Join(ci.baseDir, "src", "dashboardComponent", "components"),
	}

	for _, dir := range targetDirs {
		if err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}
			if !info.IsDir() && strings.HasSuffix(info.Name(), ".vue") {
				componentPaths = append(componentPaths, path)
			}
			return nil
		}); err != nil {
			logs.FWarn("Error walking directory %s: %v", dir, err)
		}
	}

	logs.FInfo("Found %d Vue components", len(componentPaths))

	// Parse each component
	for _, path := range componentPaths {
		if metadata, err := ci.parseComponent(path); err != nil {
			logs.FWarn("Error parsing component %s: %v", path, err)
			continue
		} else {
			ci.components = append(ci.components, metadata)
		}
	}

	// Upload to Qdrant
	if err := ci.uploadToQdrant(); err != nil {
		logs.FError("Error uploading to Qdrant: %v", err)
		return err
	}

	logs.FInfo("Component indexing completed. Total: %d", len(ci.components))
	return nil
}

// parseComponent extracts metadata from a Vue component file
func (ci *ComponentIndexer) parseComponent(filePath string) (ComponentMetadata, error) {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return ComponentMetadata{}, err
	}

	contentStr := string(content)
	relPath, _ := filepath.Rel(ci.baseDir, filePath)

	metadata := ComponentMetadata{
		Path:         filePath,
		RelativePath: relPath,
		Props:        make(map[string]string),
		Purpose:      make([]string, 0),
		Tags:         make([]string, 0),
		Dependencies: make([]string, 0),
		IndexedAt:    time.Now(),
	}

	// Extract component name from file
	metadata.Name = strings.TrimSuffix(filepath.Base(filePath), ".vue")
	metadata.ID = strings.ToLower(metadata.Name) + "_" + fmt.Sprintf("%d", time.Now().Unix()%10000)

	// Extract script content
	scriptRegex := regexp.MustCompile(`(?s)<script[^>]*>(.*?)</script>`)
	scriptMatches := scriptRegex.FindStringSubmatch(contentStr)
	if len(scriptMatches) > 1 {
		scriptContent := scriptMatches[1]

		// Extract props
		propsRegex := regexp.MustCompile(`defineProps\s*\(\{(.*?)\}\)`)
		propsMatches := propsRegex.FindStringSubmatch(scriptContent)
		if len(propsMatches) > 1 {
			metadata.Props = ci.extractProps(propsMatches[1])
		}
	}

	// Extract from template comments
	templateRegex := regexp.MustCompile(`(?s)<template>(.*?)</template>`)
	_ = templateRegex.FindStringSubmatch(contentStr)

	// Extract category from path
	if strings.Contains(relPath, "dashboardComponent") {
		metadata.Category = "chart"
	} else if strings.Contains(relPath, "dialogs") {
		metadata.Category = "dialog"
	} else if strings.Contains(relPath, "bars") {
		metadata.Category = "bar"
	} else if strings.Contains(relPath, "forms") {
		metadata.Category = "form"
	} else {
		metadata.Category = "component"
	}

	// Extract description and tags from comments
	if commentRegex := regexp.MustCompile(`<!--\s*@description\s*(.*?)\s*-->`); commentRegex.MatchString(contentStr) {
		matches := commentRegex.FindStringSubmatch(contentStr)
		if len(matches) > 1 {
			metadata.Description = strings.TrimSpace(matches[1])
		}
	} else {
		// Generate default description based on component name
		metadata.Description = fmt.Sprintf("Component: %s", metadata.Name)
	}

	// Add tags based on category and name
	metadata.Tags = append(metadata.Tags, metadata.Category)
	if strings.Contains(metadata.Name, "Chart") {
		metadata.Tags = append(metadata.Tags, "visualization", "chart")
	}
	if strings.Contains(metadata.Name, "Dialog") {
		metadata.Tags = append(metadata.Tags, "modal", "interaction")
	}

	// Add common dependencies
	if strings.Contains(contentStr, "apexcharts") {
		metadata.Dependencies = append(metadata.Dependencies, "ApexCharts")
	}
	if strings.Contains(contentStr, "deck.gl") {
		metadata.Dependencies = append(metadata.Dependencies, "Deck.gl")
	}
	if strings.Contains(contentStr, "mapbox") {
		metadata.Dependencies = append(metadata.Dependencies, "Mapbox GL")
	}

	// Add Vue as default dependency
	metadata.Dependencies = append(metadata.Dependencies, "Vue 3")

	// Generate usage example
	metadata.UsageExample = fmt.Sprintf("<%s />\n<!-- See component documentation for prop details -->", metadata.Name)

	return metadata, nil
}

// extractProps extracts props from the props definition
func (ci *ComponentIndexer) extractProps(propsStr string) map[string]string {
	props := make(map[string]string)
	// Simple extraction - can be enhanced with better parsing
	lines := strings.Split(propsStr, "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line != "" && !strings.HasPrefix(line, "//") {
			props[line] = "Object|String|Array|Number"
		}
	}
	return props
}

// uploadToQdrant uploads the indexed components to Qdrant vector database
func (ci *ComponentIndexer) uploadToQdrant() error {
	if ci.vectorClient == nil {
		logs.FWarn("Vector client is nil, skipping upload to Qdrant")
		return nil
	}

	logs.FInfo("Uploading %d components to Qdrant", len(ci.components))

	for i, comp := range ci.components {
		// Create vector payload
		payload := map[string]interface{}{
			"id":                   comp.ID,
			"name":                 comp.Name,
			"path":                 comp.RelativePath,
			"category":             comp.Category,
			"description":          comp.Description,
			"purpose":              comp.Purpose,
			"props":                comp.Props,
			"tags":                 comp.Tags,
			"dependencies":         comp.Dependencies,
			"usage_example":        comp.UsageExample,
			"related_components":   comp.RelatedComponent,
			"indexed_at":           comp.IndexedAt,
		}

		// Upload to Qdrant
		if err := ci.vectorClient.UpsertPoint(comp.ID, comp.Description, payload); err != nil {
			logs.FError("Error upserting component %s to Qdrant: %v", comp.Name, err)
			continue
		}

		if (i+1)%10 == 0 {
			logs.FInfo("Uploaded %d/%d components", i+1, len(ci.components))
		}
	}

	logs.FInfo("Component upload to Qdrant completed")
	return nil
}

// GetIndexedComponents returns all indexed components
func (ci *ComponentIndexer) GetIndexedComponents() []ComponentMetadata {
	return ci.components
}

// ExportManifest exports the component manifest as JSON
func (ci *ComponentIndexer) ExportManifest(outputPath string) error {
	data, err := json.MarshalIndent(ci.components, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(outputPath, data, 0644)
}
