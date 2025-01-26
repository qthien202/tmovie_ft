// import 'package:flutter/foundation.dart';
// import 'package:flutter/widgets.dart';
//
// class TabbarView extends StatelessWidget {
//   const TabbarView({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Shortcuts(
//         shortcuts: <LogicalKeySet, Intent>{
//           LogicalKeySet(LogicalKeyboardKey.select):
//           const ActivateIntent(),
//         },
//         child: SizedBox(
//             height: 50,
//             child: Row(
//               children: categories.asMap().entries.map((entry){
//                 final category = entry.value;
//                 final index = entry.key;
//                 return InkWell(
//                     onFocusChange: (hasFocus) {
//                       setState(() {
//                         controller.tabIndex.value = index;
//                         controller.isFocusTab.value = hasFocus;
//                         print(
//                             ">>>>>>>>>>>>>${controller.isFocusTab.value}");
//                         // _handleTabChange(index);
//                       });
//                     },
//                     onTap: () {
//                       controller.selectTab.value = index;
//                       _handleTabChange(index);
//                     },
//                     child: Container(
//                       // padding: const EdgeInsets.all(1),
//                         padding: EdgeInsets.symmetric(horizontal: 10),
//                         decoration: BoxDecoration(
//                           color: Colors.transparent,
//                           border: Border(
//                             bottom: BorderSide(
//                                 color: controller.isFocusTab.value &&
//                                     controller.tabIndex.value ==
//                                         index
//                                     ? GlobalColor.primary
//                                     : Colors.transparent,
//                                 width: 3),
//                           ),
//                         ),
//                         child: Text(
//                           category["title"],
//                           style: TextStyle(
//                               color: controller.tabIndex.value == index||
//                                   controller.selectTab.value ==
//                                       index
//                                   ? Colors.white
//                                   : Colors.grey,
//                               fontSize: controller.isFocusTab.value &&
//                                   controller.tabIndex.value ==
//                                       index
//                                   ? 20
//                                   : 16,
//                               fontWeight: FontWeight.bold),
//                         )));
//               }).toList(),
//             )
//         ));
//   }
// }