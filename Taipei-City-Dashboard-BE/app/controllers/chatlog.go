// // Package controllers stores all the controllers for the Gin router.
package controllers

import (
	"TaipeiCityDashboardBE/app/cache"
	"TaipeiCityDashboardBE/app/models"
	"encoding/json"
	"fmt"
	"html"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)
func CreateChatLog(c *gin.Context) {
	var chatLog models.ChatLog
	
	accountID, exists  := c.Get("accountID")

	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "Unauthorized"})
		return
	}

	// Sanitize input to prevent XSS
	session := c.PostForm("session")
	question := c.PostForm("question")
	answer := c.PostForm("answer")
	answerMode := c.DefaultPostForm("answer_mode", "unknown")
	usedToolsRaw := c.DefaultPostForm("used_tools", "[]")
	ipAddress := c.ClientIP()
	session = html.EscapeString(session)
	question = html.EscapeString(question)
	answer = html.EscapeString(answer)
	answerMode = html.EscapeString(answerMode)

	usedTools := make([]string, 0)
	if err := json.Unmarshal([]byte(usedToolsRaw), &usedTools); err != nil {
		usedTools = []string{}
	}
	usedToolsBytes, _ := json.Marshal(usedTools)

	chatLog, err := models.CreateChatLog(session, question, answer, answerMode, string(usedToolsBytes), ipAddress, accountID.(int))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "success", "data": chatLog})
}

func GetALLChatLog(c *gin.Context) {
	var chatLogList []models.ChatLog
	
	accountID, exists  := c.Get("accountID")

	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "Unauthorized"})
		return
	}

	chatLogList, _ = models.GetALLChatLogSession(accountID.(int))

	type ChatLogSummary struct {
		Session   string    `json:"session"`		
		CreatedAt time.Time `json:"created_at"`
	}

    var summaries []ChatLogSummary
    for _, log := range chatLogList {
        summaries = append(summaries, ChatLogSummary{
            Session:   log.Session,
            CreatedAt: log.CreatedAt,
        })
    }

	c.JSON(http.StatusOK, gin.H{"status": "success", "data": summaries})
}

func GetChatLogDetailBySession(c *gin.Context) {

	var chatLogList []models.ChatLog
	session := c.Param("session")
	session = html.EscapeString(session)
	accountID, exists  := c.Get("accountID")

	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "Unauthorized"})
		return
	}

	chatLogList, _ = models.GetChatLogDetailBySession(session, accountID.(int))
	c.JSON(http.StatusOK, gin.H{"status": "success", "data": chatLogList})
}

// GetChatLogStats is an admin-only endpoint that returns daily answer_mode KPI breakdown.
// GET /api/v1/chatlog/stats?days=30
func GetChatLogStats(c *gin.Context) {
	days := 30
	if d := c.Query("days"); d != "" {
		if parsed, err := strconv.Atoi(d); err == nil {
			days = parsed
		}
	}

	// Redis cache: TTL 5 min per (days) bucket
	cacheKey := fmt.Sprintf("chatlog:stats:days=%d", days)
	type statsPayload struct {
		Days    int            `json:"days"`
		Total   int            `json:"total"`
		Totals  map[string]int `json:"totals"`
		Daily   []models.ChatLogStatRow `json:"daily"`
	}

	if cached, err := cache.Redis.Get(cacheKey).Result(); err == nil {
		var payload statsPayload
		if json.Unmarshal([]byte(cached), &payload) == nil {
			c.JSON(http.StatusOK, gin.H{"status": "success", "cached": true, "data": payload})
			return
		}
	}

	rows, err := models.GetChatLogStats(days)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}

	totals := make(map[string]int)
	var grandTotal int
	for _, r := range rows {
		totals[r.AnswerMode] += r.Count
		grandTotal += r.Count
	}

	payload := statsPayload{Days: days, Total: grandTotal, Totals: totals, Daily: rows}
	if b, err := json.Marshal(payload); err == nil {
		cache.Redis.Set(cacheKey, string(b), 5*time.Minute)
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "cached": false, "data": payload})
}
