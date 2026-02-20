import Foundation

enum WeatherRunningTips {

    static func tips(for weather: WeatherSnapshot) -> [String] {
        var tips: [String] = []

        if weather.temperatureCelsius > 30 {
            tips.append("Hot conditions — drink more frequently and reduce intensity")
        } else if weather.temperatureCelsius > 25 {
            tips.append("Warm conditions — carry extra water and stay hydrated")
        }

        if weather.temperatureCelsius < 0 {
            tips.append("Freezing conditions — wear thermal layers and protect extremities")
        } else if weather.temperatureCelsius < 5 {
            tips.append("Cold conditions — layer up and warm up longer before starting")
        }

        if weather.precipitationChance > 0.7 {
            tips.append("Rain likely — wear a waterproof layer and watch for slippery trails")
        } else if weather.precipitationChance > 0.4 {
            tips.append("Chance of rain — consider packing a lightweight waterproof")
        }

        if weather.windSpeedKmh > 40 {
            tips.append("Very strong wind — adjust effort on exposed ridges and be cautious on narrow trails")
        } else if weather.windSpeedKmh > 25 {
            tips.append("Windy conditions — expect higher effort on exposed sections")
        }

        if weather.uvIndex > 8 {
            tips.append("Very high UV — apply sunscreen, wear a hat and sunglasses")
        } else if weather.uvIndex > 5 {
            tips.append("High UV — wear sunscreen and a cap for sun protection")
        }

        return tips
    }
}
