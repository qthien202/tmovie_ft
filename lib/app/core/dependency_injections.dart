
import 'dart:io';
import 'package:app_ft_movies/app/data/apis/services.dart';
import 'package:curl_logger_dio_interceptor/curl_logger_dio_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart'as GET;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';


class DependencyInjections implements GET.Bindings {
  @override
  Future<void> dependencies() async {
       final dio = await GET.Get.putAsync(() => _dio());
       GET.Get.put(Services(dio));
       
  
  }

  Future<Dio> _dio() async {
    var dio = Dio();
    
    if(kDebugMode){
      dio.interceptors.add(CurlLoggerDioInterceptor(
      printOnSuccess: true
    ));
    dio.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90));
    }
    


      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          var fileResponse = await DefaultCacheManager().getFileFromCache(options.uri.toString());
          if (fileResponse != null && fileResponse.file.existsSync()) {
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: await fileResponse.file.readAsBytes(),

            ));
          } else {
            final SharedPreferences prefs = await SharedPreferences.getInstance();
            
            options.headers = {
              "Access-Control-Allow-Origin": "*",
              

              ...options.headers,
            };
            handler.next(options);
          }

        },

        // },
          onError: ( error, handler) async{
          if(error.response?.statusCode == HttpStatus.unauthorized){
           
          }
          else{
            handler.next(error);
          }


          },
        onResponse: (response,handler)async{
          
          if (response.statusCode == 200 && response.data is List<int>) {
            await DefaultCacheManager().putFile(response.requestOptions.uri.toString(), response.data);
          }
          handler.next(response);
        }
      
      ));
      return dio;

    }



  
}