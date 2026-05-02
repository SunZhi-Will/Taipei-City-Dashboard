package models

import (
	"context"
	"fmt"
	"strings"
	"time"
)


type ChatLog struct {
	ID         int       `json:"id" gorm:"column:id;autoincrement;primaryKey"`
	Session    string    `json:"session" gorm:"column:session;type:varchar;not null;index:idx_chat_logs_session"`
	Question   string    `json:"question" gorm:"column:question;type:text"`
	Answer     string    `json:"answer" gorm:"column:answer;type:text"`
	AnswerMode string    `json:"answer_mode" gorm:"column:answer_mode;type:varchar(50);default:'unknown'"`
	UsedTools  string    `json:"used_tools" gorm:"column:used_tools;type:text;default:'[]'"`
	IPAddress  string    `json:"ip_address" gorm:"column:ip_address;type:varchar(45);not null"`
	UserID     int       `json:"-" gorm:"column:user_id;type:int;not null;index:idx_chat_logs_user_id"`
	CreatedAt  time.Time `json:"created_at" gorm:"column:created_at;type:timestamp with time zone;not null"`
	UpdatedAt  time.Time `json:"-" gorm:"column:updated_at;type:timestamp with time zone;not null"`
}

func ensureChatLogAIMetadataColumns() (hasAnswerMode bool, hasUsedTools bool) {
	if DBManager == nil {
		return false, false
	}
	m := DBManager.Migrator()
	hasAnswerMode = m.HasColumn(&ChatLog{}, "AnswerMode")
	hasUsedTools = m.HasColumn(&ChatLog{}, "UsedTools")

	if !hasAnswerMode {
		_ = m.AddColumn(&ChatLog{}, "AnswerMode")
		hasAnswerMode = m.HasColumn(&ChatLog{}, "AnswerMode")
	}
	if !hasUsedTools {
		_ = m.AddColumn(&ChatLog{}, "UsedTools")
		hasUsedTools = m.HasColumn(&ChatLog{}, "UsedTools")
	}
	return hasAnswerMode, hasUsedTools
}

func CreateChatLog(session string, question string, answer string, answerMode string, usedTools string, ipAddress string, userID int) (chatLog ChatLog, err error) {
	chatLog = ChatLog{
		Session:    session,
		Question:   question,
		Answer:     answer,
		AnswerMode: answerMode,
		UsedTools:  usedTools,
		IPAddress:  ipAddress,
		UserID:     userID,
		CreatedAt:  time.Now(),
		UpdatedAt:  time.Now(),
	}

	hasAnswerMode, hasUsedTools := ensureChatLogAIMetadataColumns()
	db := DBManager
	if !hasAnswerMode {
		db = db.Omit("AnswerMode")
	}
	if !hasUsedTools {
		db = db.Omit("UsedTools")
	}

	err = db.Create(&chatLog).Error
	if err != nil {
		return chatLog, err
	}

	return chatLog, nil
}

func GetALLChatLogSession(UserID int)(chatLogList []ChatLog,err error){

	err = DBManager.Raw(`
		SELECT DISTINCT ON (session) *
		FROM chat_logs
		WHERE user_id = ?
		ORDER BY session, created_at ASC
	`, UserID).Scan(&chatLogList).Error
	
	if err != nil {
		return chatLogList, err
	}

	return chatLogList, nil
}

// DeleteOldChatLogs deletes chat logs older than the specified number of months.
// It returns the number of rows affected and an error, if any.
func DeleteOldChatLogs(ctx context.Context, months int) (int64, error) { // Modified function signature
    cutoffDate := time.Now().AddDate(0, -months, 0)
    db := DBManager.WithContext(ctx).Where("created_at < ?", cutoffDate).Delete(&ChatLog{}) // Use WithContext
    return db.RowsAffected, db.Error // Return rows affected and error
}

func GetChatLogDetailBySession(Session string, UserID int) (chatLogList []ChatLog, err error) {
	err = DBManager.
		Table("chat_logs").
		Where("user_id = ?", UserID).
		Where("session = ?", Session).
		Find(&chatLogList).
		Error
	if err != nil {
		return chatLogList, err
	}
	return chatLogList, nil
}

// ChatLogStatRow represents one answer_mode group in the KPI stats result.
type ChatLogStatRow struct {
	Date       string `json:"date" gorm:"column:date"`
	AnswerMode string `json:"answer_mode" gorm:"column:answer_mode"`
	Count      int    `json:"count" gorm:"column:count"`
}

// GetChatLogStats returns daily answer_mode distribution for admin KPI.
// days: how many calendar days to look back (default 30, max 365).
func GetChatLogStats(days int) ([]ChatLogStatRow, error) {
	if days <= 0 || days > 365 {
		days = 30
	}
	var rows []ChatLogStatRow
	// Use fmt.Sprintf to safely build the interval string (days is already validated above).
	interval := fmt.Sprintf("%d days", days)

	hasAnswerMode, _ := ensureChatLogAIMetadataColumns()
	var err error
	if hasAnswerMode {
		err = DBManager.Raw(`
		SELECT
			DATE(created_at AT TIME ZONE 'Asia/Taipei')          AS date,
			COALESCE(NULLIF(answer_mode, ''), 'unknown')          AS answer_mode,
			COUNT(*)                                              AS count
		FROM chat_logs
		WHERE created_at >= NOW() - CAST(? AS INTERVAL)
		GROUP BY date, answer_mode
		ORDER BY date DESC, answer_mode
		`, interval).Scan(&rows).Error

		// Safety net for environments where DB schema is older than model definition.
		if err != nil && strings.Contains(strings.ToLower(err.Error()), "answer_mode") {
			hasAnswerMode = false
		}
	}

	if !hasAnswerMode {
		err = DBManager.Raw(`
		SELECT
			DATE(created_at AT TIME ZONE 'Asia/Taipei') AS date,
			'unknown' AS answer_mode,
			COUNT(*) AS count
		FROM chat_logs
		WHERE created_at >= NOW() - CAST(? AS INTERVAL)
		GROUP BY date
		ORDER BY date DESC
		`, interval).Scan(&rows).Error
	}

	return rows, err
}