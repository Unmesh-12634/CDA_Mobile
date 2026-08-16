package com.cda.backend.model;

public class SubscriptionInfo {
    private int trialsRemaining;
    private int trialsTotal;
    private boolean isPro;
    private String planName;
    private String billingCycle;
    private String proStartedAt;
    private String proExpiresAt;
    private long secondsRemaining;
    private long daysRemaining;
    private boolean isExpired;

    public SubscriptionInfo() {}

    public SubscriptionInfo(int trialsRemaining, int trialsTotal, boolean isPro, String planName,
                            String billingCycle, String proStartedAt, String proExpiresAt,
                            long secondsRemaining, long daysRemaining, boolean isExpired) {
        this.trialsRemaining = trialsRemaining;
        this.trialsTotal = trialsTotal;
        this.isPro = isPro;
        this.planName = planName;
        this.billingCycle = billingCycle;
        this.proStartedAt = proStartedAt;
        this.proExpiresAt = proExpiresAt;
        this.secondsRemaining = secondsRemaining;
        this.daysRemaining = daysRemaining;
        this.isExpired = isExpired;
    }

    public int getTrialsRemaining() { return trialsRemaining; }
    public void setTrialsRemaining(int trialsRemaining) { this.trialsRemaining = trialsRemaining; }

    public int getTrialsTotal() { return trialsTotal; }
    public void setTrialsTotal(int trialsTotal) { this.trialsTotal = trialsTotal; }

    public boolean isPro() { return isPro; }
    public void setPro(boolean pro) { isPro = pro; }

    public String getPlanName() { return planName; }
    public void setPlanName(String planName) { this.planName = planName; }

    public String getBillingCycle() { return billingCycle; }
    public void setBillingCycle(String billingCycle) { this.billingCycle = billingCycle; }

    public String getProStartedAt() { return proStartedAt; }
    public void setProStartedAt(String proStartedAt) { this.proStartedAt = proStartedAt; }

    public String getProExpiresAt() { return proExpiresAt; }
    public void setProExpiresAt(String proExpiresAt) { this.proExpiresAt = proExpiresAt; }

    public long getSecondsRemaining() { return secondsRemaining; }
    public void setSecondsRemaining(long secondsRemaining) { this.secondsRemaining = secondsRemaining; }

    public long getDaysRemaining() { return daysRemaining; }
    public void setDaysRemaining(long daysRemaining) { this.daysRemaining = daysRemaining; }

    public boolean isExpired() { return isExpired; }
    public void setExpired(boolean expired) { isExpired = expired; }
}
