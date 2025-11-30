# Visual Guide: Node Modal & AI Review Features

## Feature 1: Node Information Modal

### Visual Layout

```
┌─────────────────────────────────────────────────────────┐
│  Semi-transparent black background (click to close)     │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Graph Canvas (behind modal)                      │  │
│  │                                                  │  │
│  │  ┌────────────────────────────────────────────┐ │  │
│  │  │  ┌─────────────────────────────────────┐  │ │  │
│  │  │  │ ● Photosynthesis          [Close X] │  │ │  │
│  │  │  ├─────────────────────────────────────┤  │ │  │
│  │  │  │                                     │  │ │  │
│  │  │  │ Definition                          │  │ │  │
│  │  │  │ ┌─────────────────────────────────┐ │  │ │  │
│  │  │  │ │ The process by which plants    │ │  │ │  │
│  │  │  │ │ convert light energy into      │ │  │ │  │
│  │  │  │ │ chemical energy...             │ │  │ │  │
│  │  │  │ └─────────────────────────────────┘ │  │ │  │
│  │  │  │                                     │  │ │  │
│  │  │  │ 💡 Try connecting this concept    │  │ │  │
│  │  │  │    to others to build your        │  │ │  │
│  │  │  │    understanding.                 │  │ │  │
│  │  │  │                                     │  │ │  │
│  │  │  │ [Close]                            │  │ │  │
│  │  │  └─────────────────────────────────────┘  │ │  │
│  │  │                                           │ │  │
│  │  └────────────────────────────────────────────┘ │  │
│  │                                                  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### User Interaction Flow

```
User on Graph Canvas
        ↓
    Tap Node
        ↓
Modal Appears
├─ Node Name (with color indicator)
├─ Definition Box
├─ Learning Tip (with lightbulb icon)
└─ Close Button
        ↓
   Read Content
        ↓
Click Outside or Close Button
        ↓
Modal Disappears
        ↓
Continue with Activity
```

### Color Scheme

| Element | Color | Hex |
|---------|-------|-----|
| Border | Blue | #74C0FC |
| Background | Dark Grey | #1a1a1a |
| Title Text | Blue | #74C0FC |
| Body Text | Light Grey | #d0d0d0 |
| Tip Background | Blue (10% opacity) | #74C0FC |
| Icon | Blue | #74C0FC |

---

## Feature 2: AI Review & Coaching Panel

### Visual Layout

```
┌─────────────────────────────────────────────────────────┐
│  Semi-transparent black background (click to close)     │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │                                                  │  │
│  │  ✨ AI Review & Coaching                [Close] │  │
│  │  Concept Cartographer - Photosynthesis         │  │
│  │  ────────────────────────────────────────────  │  │
│  │                                                  │  │
│  │  Overall Insights                              │  │
│  │  ┌────────────────────────────────────────────┐ │  │
│  │  │ Excellent work! You've created a well-    │ │  │
│  │  │ connected concept map with strong         │ │  │
│  │  │ relationships between ideas...             │ │  │
│  │  └────────────────────────────────────────────┘ │  │
│  │                                                  │  │
│  │  Detailed Feedback                             │  │
│  │                                                  │  │
│  │  ┌────────────────────────────────────────────┐ │  │
│  │  │ 💡 What should you learn next?      [▼]   │ │  │
│  │  ├────────────────────────────────────────────┤ │  │
│  │  │ Focus on understanding how...              │ │  │
│  │  └────────────────────────────────────────────┘ │  │
│  │                                                  │  │
│  │  ┌────────────────────────────────────────────┐ │  │
│  │  │ ⚠️  Gaps in knowledge                [▶]   │ │  │
│  │  └────────────────────────────────────────────┘ │  │
│  │                                                  │  │
│  │  ┌────────────────────────────────────────────┐ │  │
│  │  │ ✓ Strengths to build on              [▶]   │ │  │
│  │  └────────────────────────────────────────────┘ │  │
│  │                                                  │  │
│  │  ┌────────────────────────────────────────────┐ │  │
│  │  │ 🔗 Connection quality                [▶]   │ │  │
│  │  └────────────────────────────────────────────┘ │  │
│  │                                                  │  │
│  │  [Back to Activities]                          │  │
│  │                                                  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Expanded Section View

```
┌────────────────────────────────────────────┐
│ 💡 What should you learn next?      [▲]   │
├────────────────────────────────────────────┤
│                                            │
│ Focus on understanding how Chlorophyll,   │
│ Water Splitting, and Glucose Production   │
│ relate to other concepts. These are key   │
│ nodes that should have more connections. │
│                                            │
└────────────────────────────────────────────┘
```

### User Interaction Flow

```
Activity Complete
        ↓
Results Dialog
├─ Score: 85/100
├─ Metrics Display
└─ [Review] [Continue]
        ↓
Click "Review"
        ↓
AI Review Panel Opens
├─ Overall Insights (always visible)
├─ Collapsible Sections:
│  ├─ 💡 What should you learn next?
│  ├─ ⚠️  Gaps in knowledge
│  ├─ ✓ Strengths to build on
│  ├─ 🔗 Connection quality
│  └─ 🎓 Coaching tips
└─ [Back to Activities]
        ↓
Expand/Collapse Sections
        ↓
Read Detailed Feedback
        ↓
Click "Back to Activities"
        ↓
Return to Activity List
```

### Color Scheme

| Element | Color | Hex | Usage |
|---------|-------|-----|-------|
| Primary | Blue | #74C0FC | Borders, titles, links |
| Success | Green | #51CF66 | Strengths, positive feedback |
| Warning | Orange | #FF922B | Gaps, areas to improve |
| Info | Yellow | #FFD93D | Learning recommendations |
| Coaching | Purple | #B197FC | Guidance and tips |
| Background | Dark Grey | #1a1a1a | Panel background |
| Text | Light Grey | #d0d0d0 | Body text |

### Icon Legend

| Icon | Meaning | Color |
|------|---------|-------|
| 💡 | Learning recommendations | Yellow |
| ⚠️ | Gaps in knowledge | Orange |
| ✓ | Strengths | Green |
| 🔗 | Connections | Blue |
| 🎓 | Coaching | Purple |
| ✨ | AI insights | Blue |

---

## Integration Points

### In Graph Canvas

```
User Interaction
        ↓
    Tap Node?
    /        \
  Yes        No
  /            \
Show Modal    Continue
```

### In Activity Results

```
Activity Complete
        ↓
Results Dialog
        ↓
    Review?
    /      \
  Yes      No
  /          \
Show AI      Continue
Review Panel
```

---

## Responsive Design

### Mobile (< 600px)
- Modal takes 90% of screen width
- Larger touch targets (48px minimum)
- Collapsible sections for space efficiency
- Single column layout

### Tablet (600px - 1200px)
- Modal takes 70% of screen width
- Balanced spacing
- Smooth animations
- Two-column layout possible

### Desktop (> 1200px)
- Modal takes 60% of screen width
- Precise cursor interactions
- Rich animations
- Multi-column layout

---

## Animation Details

### Node Modal
- **Entrance**: Fade in + scale (200ms)
- **Exit**: Fade out + scale (150ms)
- **Easing**: EaseInOutCubic

### Review Panel
- **Entrance**: Slide up + fade (300ms)
- **Section expand**: Height animation (200ms)
- **Easing**: EaseInOutCubic

### Collapsible Sections
- **Expand**: 200ms smooth height increase
- **Collapse**: 150ms smooth height decrease
- **Icon rotation**: 180° rotation (200ms)

---

## Accessibility Features

### Node Modal
- ✅ Keyboard navigation (Tab, Enter, Escape)
- ✅ Screen reader support
- ✅ High contrast colors
- ✅ Clear close button
- ✅ Click outside to dismiss

### Review Panel
- ✅ Keyboard navigation (Tab, Enter, Arrow keys)
- ✅ Screen reader support
- ✅ Icon + text labels
- ✅ Clear section headers
- ✅ Semantic HTML structure

---

## Performance Metrics

### Node Modal
- **Load time**: < 50ms
- **Animation FPS**: 60 FPS
- **Memory**: < 1MB
- **Render time**: < 16ms per frame

### Review Panel
- **Load time**: < 100ms
- **Animation FPS**: 60 FPS
- **Memory**: < 2MB
- **Render time**: < 16ms per frame

---

## Example Scenarios

### Scenario 1: Student Learning Photosynthesis
```
1. Student sees 5 concept nodes
2. Taps "Chlorophyll" node
3. Modal shows definition
4. Student reads and closes
5. Taps "Water Splitting" node
6. Reads definition
7. Draws connection between them
8. Completes activity
9. Clicks "Review"
10. Sees AI feedback on connections
11. Learns what to study next
```

### Scenario 2: Student Reviewing Performance
```
1. Activity completes
2. Results dialog shows score: 78/100
3. Student clicks "Review"
4. AI Review Panel opens
5. Reads overall insights
6. Expands "Gaps in knowledge"
7. Sees specific areas to improve
8. Expands "Coaching tips"
9. Gets actionable advice
10. Clicks "Back to Activities"
11. Returns to activity list
```

---

## Design Principles

### 1. **Clarity**
- Clear hierarchy of information
- Obvious call-to-action buttons
- Readable typography

### 2. **Consistency**
- Matches app design language
- Consistent colors and spacing
- Familiar interaction patterns

### 3. **Efficiency**
- Quick to open and close
- Minimal scrolling needed
- Fast animations

### 4. **Feedback**
- Visual feedback on interactions
- Clear state indicators
- Smooth transitions

### 5. **Accessibility**
- Keyboard navigation
- Screen reader support
- High contrast colors
- Clear labels

---

## Summary

Both features provide:
- ✅ Beautiful, modern UI
- ✅ Smooth animations
- ✅ Responsive design
- ✅ Accessibility support
- ✅ Fast performance
- ✅ Intuitive interactions

**Result**: Enhanced learning experience with just-in-time information and personalized AI coaching!
