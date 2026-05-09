#!/bin/bash
# Doubao AI Skill - Image & Video Generation
# Usage: ./doubao.sh <action> [args]

API_KEY="${ARK_API_KEY:-}"
BASE_URL="https://ark.cn-beijing.volces.com/api/v3"

if [ -z "$API_KEY" ]; then
    echo "错误：请先在环境变量 ARK_API_KEY 中设置你的 API Key"
    echo "获取地址：https://console.volcengine.com/ark"
    exit 1
fi

action="$1"
shift

case "$action" in
    img)
        prompt="$1"
        if [ -z "$prompt" ]; then
            echo "用法：$0 img <提示词>"
            exit 1
        fi
        
        response=$(curl -s -X POST "$BASE_URL/images/generations" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $API_KEY" \
            -d "{
                \"model\": \"doubao-seed-2-0-pro-260215\",
                \"prompt\": \"$prompt\",
                \"n\": 1,
                \"size\": \"1024x1024\"
            }")
        
        image_url=$(echo "$response" | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4)
        
        if [ -n "$image_url" ]; then
            mkdir -p data
            filename="data/img_$(date +%Y%m%d_%H%M%S).jpeg"
            curl -s -o "$filename" "$image_url"
            echo "{\"status\":\"success\",\"image_url\":\"$image_url\",\"local_path\":\"$filename\",\"prompt\":\"$prompt\"}"
        else
            echo "错误：图片生成失败"
            echo "$response"
            exit 1
        fi
        ;;
    
    edit)
        image_url="$1"
        prompt="${2:-remove watermark, keep main content}"
        
        if [ -z "$image_url" ]; then
            echo "用法：$0 edit <图片 URL> [编辑提示词]"
            exit 1
        fi
        
        response=$(curl -s -X POST "$BASE_URL/images/edits" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $API_KEY" \
            -d "{
                \"model\": \"doubao-seed-2-0-pro-260215\",
                \"image_url\": \"$image_url\",
                \"prompt\": \"$prompt\"
            }")
        
        echo "$response"
        ;;
    
    vid)
        prompt="$1"
        sync_mode="${2:-async}"
        image_url="$3"
        
        if [ -z "$prompt" ]; then
            echo "用法：$0 vid <提示词> [sync|async] [图片 URL]"
            exit 1
        fi
        
        response=$(curl -s -X POST "$BASE_URL/video/generations" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $API_KEY" \
            -d "{
                \"model\": \"doubao-seed-2-0-pro-260215\",
                \"prompt\": \"$prompt\",
                ${image_url:+\"image_url\": \"$image_url\",}
            }")
        
        task_id=$(echo "$response" | grep -o '"task_id":"[^"]*"' | cut -d'"' -f4)
        
        if [ -z "$task_id" ]; then
            echo "错误：视频任务创建失败"
            echo "$response"
            exit 1
        fi
        
        if [ "$sync_mode" = "sync" ]; then
            echo "等待视频生成完成..."
            for i in {1..60}; do
                sleep 5
                status_response=$(curl -s -X GET "$BASE_URL/video/tasks/$task_id" \
                    -H "Authorization: Bearer $API_KEY")
                
                status=$(echo "$status_response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
                
                if [ "$status" = "succeeded" ]; then
                    video_url=$(echo "$status_response" | grep -o '"video_url":"[^"]*"' | cut -d'"' -f4)
                    mkdir -p data
                    filename="data/vid_$(date +%Y%m%d_%H%M%S).mp4"
                    curl -s -o "$filename" "$video_url"
                    echo "{\"status\":\"success\",\"task_id\":\"$task_id\",\"video_url\":\"$video_url\",\"local_path\":\"$filename\",\"prompt\":\"$prompt\"}"
                    exit 0
                elif [ "$status" = "failed" ]; then
                    echo "错误：视频生成失败"
                    echo "$status_response"
                    exit 1
                fi
                
                echo "进度：$i/60 - 状态：$status"
            done
            
            echo "错误：等待超时"
            exit 1
        else
            echo "{\"status\":\"success\",\"task_id\":\"$task_id\",\"prompt\":\"$prompt\"}"
        fi
        ;;
    
    status)
        task_id="$1"
        
        if [ -z "$task_id" ]; then
            echo "用法：$0 status <任务 ID>"
            exit 1
        fi
        
        response=$(curl -s -X GET "$BASE_URL/video/tasks/$task_id" \
            -H "Authorization: Bearer $API_KEY")
        
        echo "$response"
        ;;
    
    help|*)
        echo "Doubao AI Skill - 文生图/图片编辑/文生视频"
        echo ""
        echo "用法：$0 <action> [参数]"
        echo ""
        echo "动作:"
        echo "  img <提示词>                    生成图片"
        echo "  edit <图片 URL> [提示词]        编辑图片（去水印）"
        echo "  vid <提示词> [sync|async]       生成视频"
        echo "  status <任务 ID>                查询任务状态"
        echo "  help                            显示帮助"
        echo ""
        echo "示例:"
        echo "  $0 img \"一只可爱的小猫\""
        echo "  $0 edit \"https://example.com/image.png\" \"remove watermark\""
        echo "  $0 vid \"一个人在跳舞\" sync"
        echo "  $0 status \"task_xxxxx\""
        ;;
esac
