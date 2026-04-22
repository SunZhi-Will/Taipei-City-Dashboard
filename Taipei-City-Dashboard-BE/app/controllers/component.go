package controllers

import (
	"TaipeiCityDashboardBE/app/services/ai/components"
	"TaipeiCityDashboardBE/app/util"
	"TaipeiCityDashboardBE/logs"
	"fmt"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
)

var componentIndexer *components.ComponentIndexer
var vectorClient *components.VectorClient

// InitComponentIndexer initializes the component indexer (call from main app)
// feSourcePath can be empty, defaults to checking standard FE locations
func InitComponentIndexer(feSourcePath string, qdrantURL string) error {
	if qdrantURL == "" {
		logs.FWarn("Qdrant URL not provided, skipping component indexer initialization")
		return nil
	}

	// If feSourcePath is empty, try to find FE source from common locations
	if feSourcePath == "" {
		possiblePaths := []string{
			"./Taipei-City-Dashboard-FE",
			"../Taipei-City-Dashboard-FE",
			"/app/Taipei-City-Dashboard-FE",
			"./src",
		}
		
		for _, p := range possiblePaths {
			if _, err := os.Stat(p); err == nil {
				feSourcePath = p
				break
			}
		}

		if feSourcePath == "" {
			logs.FWarn("Could not find FE source path, skipping component indexer initialization")
			return nil
		}
	}

	logs.FInfo("Initializing component indexer with FE path: %s", feSourcePath)

	// Initialize vector client
	vectorClient = components.NewVectorClient(qdrantURL, "", "components")
	
	// Ensure collection exists
	if err := vectorClient.EnsureCollection(); err != nil {
		logs.FWarn("Failed to ensure Qdrant collection: %v", err)
		// Don't return error, let the system continue without it
	} else {
		logs.FInfo("Qdrant collection 'components' is ready")
	}

	// Initialize component indexer
	componentIndexer = components.NewComponentIndexer(feSourcePath, vectorClient)
	
	// Perform initial indexing (async)
	go func() {
		if err := componentIndexer.IndexComponents(); err != nil {
			logs.FWarn("Failed to index components: %v", err)
		} else {
			logs.FInfo("Component indexing completed successfully")
		}
	}()

	return nil
}

// ReindexComponents reindexes all Vue components from the frontend source
// POST /api/v1/admin/ai/reindex-components
func ReindexComponents(c *gin.Context) {
	// Admin-only endpoint
	_, _, isAdmin, _, _ := util.GetUserInfoFromContext(c)

	if !isAdmin {
		c.JSON(http.StatusForbidden, gin.H{
			"status": "error",
			"message": "Admin access required",
		})
		return
	}

	if componentIndexer == nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status": "error",
			"message": "Component indexer not initialized",
		})
		return
	}

	// Perform indexing
	if err := componentIndexer.IndexComponents(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status": "error",
			"message": fmt.Sprintf("Indexing failed: %v", err),
		})
		return
	}

	components := componentIndexer.GetIndexedComponents()
	
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": gin.H{
			"total_indexed": len(components),
			"timestamp": "now",
		},
	})
}

// GetComponentSource retrieves the source code of a specific component
// GET /api/v1/components/source/:id
func GetComponentSource(c *gin.Context) {
	componentID := c.Param("id")
	
	if componentIndexer == nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status": "error",
			"message": "Component service not initialized",
		})
		return
	}

	// Find component by ID
	allComps := componentIndexer.GetIndexedComponents()
	var foundComponent *components.ComponentMetadata

	for i := range allComps {
		if allComps[i].ID == componentID {
			foundComponent = &allComps[i]
			break
		}
	}

	if foundComponent == nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status": "error",
			"message": "Component not found",
		})
		return
	}

	// Read source file
	sourceCode, err := os.ReadFile(foundComponent.Path)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status": "error",
			"message": fmt.Sprintf("Failed to read source: %v", err),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": gin.H{
			"id":           foundComponent.ID,
			"name":         foundComponent.Name,
			"path":         foundComponent.RelativePath,
			"source":       string(sourceCode),
			"language":     "vue",
			"props":        foundComponent.Props,
			"description": foundComponent.Description,
		},
	})
}

// SearchComponents searches for components by query
// GET /api/v1/components/search?query=...&limit=5
func SearchComponents(c *gin.Context) {
	query := c.DefaultQuery("query", "")
	limit := c.DefaultQuery("limit", "5")
	scoreStr := c.DefaultQuery("score_threshold", "0.78")

	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"status": "error",
			"message": "Query parameter is required",
		})
		return
	}

	if vectorClient == nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status": "error",
			"message": "Vector client not initialized",
		})
		return
	}

	var limitInt, scoreThreshold float64
	if _, err := fmt.Sscanf(limit, "%d", &limitInt); err != nil {
		limitInt = 5
	}
	if _, err := fmt.Sscanf(scoreStr, "%f", &scoreThreshold); err != nil {
		scoreThreshold = 0.78
	}

	// Search in Qdrant
	results, err := vectorClient.SearchPoints(query, int(limitInt), scoreThreshold)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status": "error",
			"message": fmt.Sprintf("Search failed: %v", err),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": gin.H{
			"query":   query,
			"count":   len(results),
			"results": results,
		},
	})
}

// GetIndexedAIComponents returns all AI-indexed Vue components (paginated)
// GET /api/v1/components/ai?page=1&limit=20
func GetIndexedAIComponents(c *gin.Context) {
	if componentIndexer == nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status": "error",
			"message": "Component indexer not initialized",
		})
		return
	}

	allComponents := componentIndexer.GetIndexedComponents()
	
	// Simple pagination
	page := c.DefaultQuery("page", "1")
	pageSize := c.DefaultQuery("limit", "20")

	var pageInt, pageSizeInt int
	fmt.Sscanf(page, "%d", &pageInt)
	fmt.Sscanf(pageSize, "%d", &pageSizeInt)

	if pageInt < 1 {
		pageInt = 1
	}
	if pageSizeInt < 1 || pageSizeInt > 100 {
		pageSizeInt = 20
	}

	start := (pageInt - 1) * pageSizeInt
	end := start + pageSizeInt

	if start >= len(allComponents) {
		allComponents = []components.ComponentMetadata{}
	} else if end > len(allComponents) {
		allComponents = allComponents[start:]
	} else {
		allComponents = allComponents[start:end]
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": gin.H{
			"page":        pageInt,
			"page_size":   pageSizeInt,
			"total":       len(componentIndexer.GetIndexedComponents()),
			"components": allComponents,
		},
	})
}

// ExportComponentsManifest exports the component manifest as JSON
// GET /api/v1/admin/components/manifest
func ExportComponentsManifest(c *gin.Context) {
	// Admin-only
	_, _, isAdmin, _, _ := util.GetUserInfoFromContext(c)

	if !isAdmin {
		c.JSON(http.StatusForbidden, gin.H{
			"status": "error",
			"message": "Admin access required",
		})
		return
	}

	if componentIndexer == nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status": "error",
			"message": "Component indexer not initialized",
		})
		return
	}

	components := componentIndexer.GetIndexedComponents()
	
	c.Header("Content-Disposition", "attachment; filename=components-manifest.json")
	c.Header("Content-Type", "application/json")
	c.JSON(http.StatusOK, components)
}
