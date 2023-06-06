package org.growerp.model;

public class Message {
    private String fromUserId;
    private String toUserId;
    private String content;
    private String chatRoomId;

    @Override
    public String toString() {
        return super.toString();
    }

    public String getFromUserId() {
        return fromUserId;
    }

    public void setFromUserId(String fromUserId) {
        this.fromUserId = fromUserId;
    }

    public String getToUserId() {
        return toUserId;
    }

    public void setToUserId(String toUserId) {
        this.toUserId = toUserId;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }
    public String getChatRoomId() {
        return chatRoomId;
    }

    public void setChatRoomid(String chatRoomId) {
        this.chatRoomId = chatRoomId;
    }
}
