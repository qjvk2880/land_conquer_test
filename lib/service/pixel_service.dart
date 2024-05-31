import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/pixel.dart';
import 'dio_service.dart';

class PixelService {
  static final PixelService _instance = PixelService._internal();

  final Dio dio = DioService().to();

  PixelService._internal();

  factory PixelService() {
    return _instance;
  }

  Future<List<Pixel>> getPixels() async {
    var response = await dio.get("/pixels");
    return Pixel.listFromJson(response.data);
  }

  updatePixel(int x, int y, int userId) async {
    var response = await dio.post('/pixels', data: {'x':x, 'y':y, 'userId': userId});
  }
}