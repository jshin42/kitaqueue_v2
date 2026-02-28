import SwiftUI

struct QuestRowView: View {
    let quest: DailyQuest

    var body: some View {
        HStack(spacing: 12) {
            // Completion indicator
            ZStack {
                Circle()
                    .stroke(quest.isCompleted ? Color.green : Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 28, height: 28)

                if quest.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.green)
                }
            }

            // Quest info
            VStack(alignment: .leading, spacing: 4) {
                Text(quest.description)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(quest.isCompleted ? .white.opacity(0.5) : .white)
                    .strikethrough(quest.isCompleted)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white.opacity(0.1))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(quest.isCompleted ? .green : .orange)
                            .frame(width: geo.size.width * quest.progress)
                    }
                }
                .frame(height: 4)
            }

            Spacer()

            // Progress counter + reward
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(min(quest.currentCount, quest.targetCount))/\(quest.targetCount)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))

                HStack(spacing: 2) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.yellow)
                    Text("+\(quest.rewardTokens)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.yellow.opacity(0.8))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(quest.isCompleted ? 0.03 : 0.06))
        )
    }
}
