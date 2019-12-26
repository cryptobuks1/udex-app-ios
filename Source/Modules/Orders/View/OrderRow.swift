import SwiftUI

struct OrderRow: View {
  let order: OrderViewItem
  
  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      Text(order.isBuy ? order.takerAmount : order.makerAmount).font(.system(size: 10))
      Spacer()
      Text("for").font(.system(size: 10))
      Spacer()
      Text(order.isBuy ? order.makerAmount : order.takerAmount).font(.system(size: 10))
    }
  }
}

struct OrderRow_Previews: PreviewProvider {
    static var previews: some View {
      OrderRow(order: TestData.orders()[0])
        .previewLayout(.fixed(width: 300, height: 50))
    }
}