package com.cda.backend.model;

public class SubscriptionInfo {
    private int trialsRemaining;
    private int trialsTotal;
    private boolean isPro;
    private String planName;

    public SubscriptionInfo() {}

    public SubscriptionInfo(int trialsRemaining, int trialsTotal, boolean isPro, String planName) {
        this.trialsRemaining = trialsRemaining;
        this.trialsTotal = trialsTotal;
        this.isPro = isPro;
        this.planName = planName;
    }

    public int getTrialsRemaining() { return trialsRemaining; }
    public void setTrialsRemaining(int trialsRemaining) { this.trialsRemaining = trialsRemaining; }

    public int getTrialsTotal() { return trialsTotal; }
    public void setTrialsTotal(int trialsTotal) { this.trialsTotal = trialsTotal; }

    public boolean isPro() { return isPro; }
    public void setPro(boolean pro) { isPro = pro; }

    public String getPlanName() { return planName; }
    public void setPlanName(String planName) { this.planName = planName; }
}
