import SwiftUI

struct BarChartView: View {
    let data: [ChartDataPoint]
    let title: String
    let maxValue: Double
    let color: Color
    
    init(data: [ChartDataPoint], title: String, color: Color = Color.theme.primary) {
        self.data = data
        self.title = title
        self.color = color
        self.maxValue = data.map(\.value).max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacing.md) {
            Text(title)
                .titleMedium()
                .foregroundColor(Color.theme.textPrimary)
            
            HStack(alignment: .bottom, spacing: .spacing.xs) {
                ForEach(data.indices, id: \.self) { index in
                    VStack(spacing: .spacing.xs) {
                        // Bar
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(
                                width: 24,
                                height: CGFloat(data[index].value / maxValue * 100)
                            )
                            .animation(.easeInOut(duration: 0.8).delay(Double(index) * 0.1), value: data)
                        
                        // Label
                        Text(data[index].label)
                            .font(.caption2)
                            .foregroundColor(Color.theme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .cardPadding()
        .background(
            RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                .fill(Color.theme.surface)
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }
}

struct LineChartView: View {
    let data: [ChartDataPoint]
    let title: String
    let color: Color
    
    @State private var animateChart = false
    
    init(data: [ChartDataPoint], title: String, color: Color = Color.theme.primary) {
        self.data = data
        self.title = title
        self.color = color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacing.md) {
            Text(title)
                .titleMedium()
                .foregroundColor(Color.theme.textPrimary)
            
            GeometryReader { geometry in
                let maxValue = data.map(\.value).max() ?? 1
                let minValue = data.map(\.value).min() ?? 0
                let range = maxValue - minValue
                let width = geometry.size.width
                let height = geometry.size.height - 30 // Leave space for labels
                
                ZStack(alignment: .bottomLeading) {
                    // Grid lines
                    VStack(spacing: 0) {
                        ForEach(0..<5) { i in
                            HStack {
                                Text("\(Int(maxValue - (range * Double(i) / 4)))")
                                    .font(.caption2)
                                    .foregroundColor(Color.theme.textTertiary)
                                    .frame(width: 30, alignment: .trailing)
                                
                                Rectangle()
                                    .fill(Color.theme.textTertiary.opacity(0.2))
                                    .frame(height: 0.5)
                            }
                            
                            if i < 4 {
                                Spacer()
                            }
                        }
                    }
                    .frame(height: height)
                    
                    // Chart line
                    Path { path in
                        guard !data.isEmpty else { return }
                        
                        let stepX = (width - 30) / Double(data.count - 1)
                        
                        for (index, point) in data.enumerated() {
                            let x = 30 + stepX * Double(index)
                            let normalizedValue = (point.value - minValue) / range
                            let y = height - (normalizedValue * height)
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .trim(from: 0, to: animateChart ? 1 : 0)
                    .stroke(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                    .animation(.easeInOut(duration: 1.5), value: animateChart)
                    
                    // Data points
                    ForEach(data.indices, id: \.self) { index in
                        let stepX = (width - 30) / Double(data.count - 1)
                        let x = 30 + stepX * Double(index)
                        let normalizedValue = (data[index].value - minValue) / range
                        let y = height - (normalizedValue * height)
                        
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                            .position(x: x, y: y)
                            .scaleEffect(animateChart ? 1 : 0)
                            .animation(.easeInOut(duration: 0.8).delay(Double(index) * 0.1), value: animateChart)
                    }
                    
                    // X-axis labels
                    HStack {
                        Spacer().frame(width: 30)
                        
                        ForEach(data.indices, id: \.self) { index in
                            if index % max(1, data.count / 4) == 0 {
                                Text(data[index].label)
                                    .font(.caption2)
                                    .foregroundColor(Color.theme.textSecondary)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Spacer()
                            }
                        }
                    }
                    .offset(y: height + 10)
                }
            }
            .frame(height: 150)
        }
        .cardPadding()
        .background(
            RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                .fill(Color.theme.surface)
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .onAppear {
            animateChart = true
        }
    }
}

struct DonutChartView: View {
    let data: [DonutChartSegment]
    let title: String
    let centerText: String
    
    @State private var animateChart = false
    
    var body: some View {
        VStack(spacing: .spacing.md) {
            Text(title)
                .titleMedium()
                .foregroundColor(Color.theme.textPrimary)
            
            HStack(spacing: .spacing.lg) {
                // Donut Chart
                ZStack {
                    ForEach(data.indices, id: \.self) { index in
                        DonutSegmentView(
                            segment: data[index],
                            startAngle: startAngle(for: index),
                            animate: animateChart
                        )
                    }
                    
                    // Center text
                    VStack(spacing: .spacing.xs) {
                        Text(centerText)
                            .titleLarge()
                            .foregroundColor(Color.theme.textPrimary)
                        
                        Text("Total")
                            .labelMedium()
                            .foregroundColor(Color.theme.textSecondary)
                    }
                }
                .frame(width: 120, height: 120)
                
                // Legend
                VStack(alignment: .leading, spacing: .spacing.sm) {
                    ForEach(data, id: \.id) { segment in
                        HStack(spacing: .spacing.xs) {
                            Circle()
                                .fill(segment.color)
                                .frame(width: 12, height: 12)
                            
                            Text(segment.label)
                                .labelMedium()
                                .foregroundColor(Color.theme.textPrimary)
                            
                            Spacer()
                            
                            Text("\(Int(segment.percentage))%")
                                .labelMedium()
                                .foregroundColor(Color.theme.textSecondary)
                        }
                    }
                }
            }
        }
        .cardPadding()
        .background(
            RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                .fill(Color.theme.surface)
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animateChart = true
            }
        }
    }
    
    private func startAngle(for index: Int) -> Angle {
        let previousPercentages = data.prefix(index).reduce(0) { $0 + $1.percentage }
        return .degrees(previousPercentages * 3.6 - 90) // -90 to start from top
    }
}

struct DonutSegmentView: View {
    let segment: DonutChartSegment
    let startAngle: Angle
    let animate: Bool
    
    private var endAngle: Angle {
        .degrees(startAngle.degrees + segment.percentage * 3.6)
    }
    
    var body: some View {
        Circle()
            .trim(from: 0, to: animate ? segment.percentage / 100 : 0)
            .stroke(
                segment.color,
                style: StrokeStyle(lineWidth: 20, lineCap: .round)
            )
            .rotationEffect(startAngle)
            .animation(.easeInOut(duration: 1.0), value: animate)
    }
}

// MARK: - Supporting Types
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

struct DonutChartSegment: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
    
    var percentage: Double {
        // This should be calculated based on total, but for simplicity we'll assume it's pre-calculated
        value
    }
}

#Preview {
    ScrollView {
        VStack(spacing: .spacing.lg) {
            BarChartView(
                data: [
                    ChartDataPoint(label: "Mon", value: 1800),
                    ChartDataPoint(label: "Tue", value: 2100),
                    ChartDataPoint(label: "Wed", value: 1950),
                    ChartDataPoint(label: "Thu", value: 2200),
                    ChartDataPoint(label: "Fri", value: 1750),
                    ChartDataPoint(label: "Sat", value: 2050),
                    ChartDataPoint(label: "Sun", value: 1900)
                ],
                title: "Daily Calories This Week"
            )
            
            LineChartView(
                data: [
                    ChartDataPoint(label: "W1", value: 1850),
                    ChartDataPoint(label: "W2", value: 1920),
                    ChartDataPoint(label: "W3", value: 1780),
                    ChartDataPoint(label: "W4", value: 2050)
                ],
                title: "Weekly Average Trend",
                color: Color.theme.secondary
            )
            
            DonutChartView(
                data: [
                    DonutChartSegment(label: "Protein", value: 25, color: Color.theme.secondary),
                    DonutChartSegment(label: "Carbs", value: 45, color: Color.theme.primary),
                    DonutChartSegment(label: "Fat", value: 30, color: Color.theme.warning)
                ],
                title: "Macro Distribution",
                centerText: "100%"
            )
        }
        .containerPadding()
    }
}