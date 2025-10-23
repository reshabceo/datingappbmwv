# 🐛 Complete Bug List - To Be Fixed

## ✅ **Already Fixed (Pending Hot Restart):**
1. Profile blurring removed from discover
2. Rewind button shows for all users (gray with PRO badge for free)
3. Premium message button shows for all users

---

## 🔴 **NEW BUGS TO FIX NOW:**

### **1. Astro Compatibility Button Missing**
- **Issue:** Button completely removed from matched profiles
- **Expected:** After matching, should show "Generate Astro Compatibility" button
- **Action:** Find and restore the astro button in match/profile screens

### **2. Call Buttons Missing in Chat Menu**
- **Issue:** No audio/video call buttons in hamburger menu
- **Expected:** Both buttons visible in chat options menu (with lock icon for free users)
- **Action:** Add call buttons to chat options menu

### **3. Expired Stories Still Showing**
- **Issue:** SS's expired story still visible in stories section
- **Expected:** Expired stories should auto-hide
- **Action:** Add expiration check to story display logic

### **4. Rewind & Message Buttons Not Showing (App Not Restarted)**
- **Issue:** Changes not reflected because app needs restart
- **Expected:** Buttons should be visible after restart
- **Status:** Code is fixed, needs hot restart

### **5. Premium Message Activity Feed Logic**
- **Issue:** Premium message notifications not implemented correctly
- **Expected Flow:**
  - Premium user sends message to free user
  - Free user sees in activity: "Someone sent you a message" (blurred profile)
  - Free user clicks → sees blurred profile with upgrade prompt
  - Match/Unmatch buttons HIDDEN while blurred
  - After upgrade → shows "(Name) sent you (message)" (clear profile)
  - Match/Unmatch buttons now VISIBLE
- **Action:** Implement complete premium message activity feed flow

---

## 🔧 **Fixes to Implement:**

### Fix #1: Restore Astro Compatibility Button
### Fix #2: Add Call Buttons to Chat Menu
### Fix #3: Hide Expired Stories
### Fix #4: Implement Premium Message Activity Logic
### Fix #5: Build Subscription Screen


