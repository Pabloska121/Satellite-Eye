import SwiftUI

struct CompassView: View {
    @ObservedObject var locationManager: Location
    @State private var northAnim = false
    
    var body: some View {
        ZStack{
            ZStack{
                HomeView(locationManager: locationManager)
            }.padding()
            VStack {
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.black.opacity(0.7))
                        .frame(width: 100, height: 50)
                        .overlay(
                            Text("\(Int(locationManager.heading))°")
                                .font(.title)
                                .foregroundColor(.white)
                        )
                        .cornerRadius(10)
                    Spacer()
                }
            }
            .padding(.top, 400)
        }
    }
}

struct HomeView: View {
    @ObservedObject var locationManager: Location
    var body: some View {
        ZStack{
            BackgroundLayers()
            CircleLayers()
            NumberLayers()
            AnimationLayers(locationManager: locationManager)
           
        }
    }
}

struct BackgroundLayers: View {
    var body: some View {
        ZStack{
            Circle()
                .fill(LinearGradient(Color.darkEnd, Color.darkStart))
                .frame(width: 320, height: 320)
                .overlay {
                    Circle().stroke(.white, lineWidth: 1)
                        }
        }
    }
}


struct CircleLayers: View {
    
    var body: some View {
        ZStack{
            ForEach(0 ..< 60) {
                Rectangle()
                    .frame(width: 3, height: 9)
                    .foregroundColor(.white)
                    .offset(y: -120)
                    .rotationEffect(.degrees(Double($0) * 45))
                    .opacity(0.2)
                    }
            
            ForEach(0 ..< 120) {
                Rectangle()
                    .frame(width: 3, height: 3)
                    .foregroundColor(.white)
                    .offset(y: -120)
                    .rotationEffect(.degrees(Double($0) * 9))
                    .opacity(0.2)
                    }
            
        
        }
    }
}



struct AnimationLayers: View {
    @ObservedObject var locationManager: Location
    
    var body: some View {
        
        
      ZStack{
        ZStack{
            Circle()
                .fill(LinearGradient(Color.darkEnd, Color.darkStart))
                .shadow(color: Color.darkStart, radius: 10, x: -2, y: -2)
                .shadow(color: Color.darkEnd, radius: 10, x: -5, y: -5)
                .frame(width: 200, height: 200)
                .overlay {
                    Circle().stroke(Color("dkgreen"), lineWidth: 10)
                        }
            
            
            Image("arrow")
                .resizable()
                .frame(width: 20, height: 20)
                .offset(x: 0, y: -100)
            
            
            Circle()
                .foregroundColor(.yellow)
                .frame(width: 8, height: 8)
                .offset(x: 0, y: -100)
                .rotationEffect(.degrees(90))
            
            Circle()
                .foregroundColor(.yellow)
                .frame(width: 8, height: 8)
                .offset(x: 0, y: -100)
                .rotationEffect(.degrees(180))
            
            Circle()
                .foregroundColor(.yellow)
                .frame(width: 8, height: 8)
                .offset(x: 0, y: -100)
                .rotationEffect(.degrees(270))
           
            
            
            Text("N")
                .font(.title2)
                .foregroundColor(.red)
                .offset(x: 0, y: -70)
            
            Text("E")
                .font(.title2)
                .foregroundColor(.white)
                .offset(x: 0, y: -70)
                .rotationEffect(.degrees(90))
            
            Text("S")
                .font(.title2)
                .foregroundColor(.white)
                .offset(x: 0, y: -70)
                .rotationEffect(.degrees(180))
            
            Text("W")
                .font(.title2)
                .foregroundColor(.white)
                .offset(x: 0, y: -70)
                .rotationEffect(.degrees(270))
         
        }.rotationEffect(.degrees(-locationManager.heading))
              
        }
    }
    
    
}


struct NumberLayers: View {
    var body: some View {
        ZStack{
            Text("0")
                .font(.subheadline)
                .foregroundColor(.white)
                .offset(x: 0, y: -140)
            
            Text("45")
                .font(.subheadline)
                .foregroundColor(.white)
                .offset(x: 0, y: -140)
                .rotationEffect(.degrees(45))
            
            
            Text("90")
                .font(.subheadline)
                .foregroundColor(.white)
                .offset(x: 0, y: -140)
                .rotationEffect(.degrees(90))
            
            Text("135")
                .font(.subheadline)
                .foregroundColor(.white)
                .offset(x: 0, y: -140)
                .rotationEffect(.degrees(135))
            
            Text("180")
                .font(.subheadline)
                .foregroundColor(.white)
                .offset(x: 0, y: -140)
                .rotationEffect(.degrees(180))
            
            Text("225")
                .font(.subheadline)
                .foregroundColor(.white)
                .offset(x: 0, y: -140)
                .rotationEffect(.degrees(225))
            
            
            Text("270")
                .font(.subheadline)
                .foregroundColor(.white)
                .offset(x: 0, y: -140)
                .rotationEffect(.degrees(270))
            
            Text("315")
                .font(.subheadline)
                .foregroundColor(.white)
                .offset(x: 0, y: -140)
                .rotationEffect(.degrees(315))
        }
    }
}

struct GearLayer: View {
    @State var gearAnim = false
    @State var widthN : CGFloat = 300
    @State var heightN : CGFloat = 300
    var body: some View {
        ZStack{
            Image(systemName: "gear")
                .resizable()
                .frame(width: widthN, height: heightN)
                .foregroundColor(.gray)
                .opacity(0.03)
                .rotationEffect(.degrees(gearAnim ? 25 : -25))
                  .onAppear {
                        withAnimation(Animation.default.repeatForever(autoreverses: true))
                         {
                             gearAnim.toggle()
                         }
                  }
        }
    }
}

extension Color {
    static let darkStart = Color("darkstart")
    static let darkEnd = Color("darkend")
}

extension LinearGradient {
    init(_ colors: Color...) {
        self.init(gradient: Gradient(colors: colors), startPoint: .topTrailing, endPoint: .bottomTrailing)
    }
}


extension RadialGradient {
    init(_ colors: Color...) {
        self.init(gradient: Gradient(colors: colors),center: .center, startRadius: 2, endRadius: 100)
    }
}
