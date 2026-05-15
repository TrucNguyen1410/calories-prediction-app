import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Sửa lỗi import bằng đường dẫn tương đối
import '../models/workout.dart';

class ApiService {
    static const String _baseUrl = 'http://127.0.0.1:3000/api';


    
    static const String _tokenKey = 'authToken';
    static const String _userKey = 'userData';


    // --- Hàm lưu trữ nội bộ (Auth) ---

    Future<void> _saveAuthData(String token, Map<String, dynamic> userData) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userKey, jsonEncode(userData));
    }

    Future<String?> getToken() async {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_tokenKey);
    }

    Future<Map<String, dynamic>?> getUserData() async {
        final prefs = await SharedPreferences.getInstance();
        final userDataString = prefs.getString(_userKey);
        if (userDataString != null) {
            return jsonDecode(userDataString) as Map<String, dynamic>;
        }
        return null;
    }

    Future<void> logout() async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);
        await prefs.remove(_userKey);
        // Clear all meal entries for this device (since they're user-specific)
        final keys = prefs.getKeys();
        for (final key in keys) {
            if (key.startsWith('meals_')) {
                await prefs.remove(key);
            }
        }
    }


    // --- Các hàm gọi API Auth ---

    Future<Map<String, dynamic>> loginUser({
        required String email,
        required String password,
    }) async {
        try {
            final response = await http.post(
                Uri.parse('$_baseUrl/auth/login'),
                headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                },
                body: jsonEncode(<String, String>{
                    'email': email,
                    'password': password,
                }),
            );

            if (response.statusCode == 200) {
                final body = jsonDecode(response.body);
                // Dữ liệu user (có height, weight) sẽ được lưu ở đây
                await _saveAuthData(body['token'], body['user']);
                return {
                    'success': true,
                    'message': 'Đăng nhập thành công',
                    'user': body['user'],
                    'token': body['token'],
                };
            } else {
                final body = jsonDecode(response.body);
                return {'success': false, 'message': body['message'] ?? 'Đăng nhập thất bại'};
            }
        } catch (e) {
            return {'success': false, 'message': 'Không thể kết nối đến máy chủ. ' + e.toString()};
        }
    }

    Future<Map<String, dynamic>> registerUser({
        required String name,
        required String email,
        required String password,
        required String gender,
        required String birthdate,
    }) async {
        try {
            final response = await http.post(
                Uri.parse('$_baseUrl/auth/register'),
                headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                },
                body: jsonEncode(<String, String>{
                    'name': name,
                    'email': email,
                    'password': password,
                    'gender': gender,
                    'birthdate': birthdate,
                }),
            );

            if (response.statusCode == 201) {
                return {'success': true, 'message': 'Đăng ký tài khoản thành công'};
            } else {
                final body = jsonDecode(response.body);
                return {'success': false, 'message': body['message'] ?? 'Đăng ký thất bại'};
            }
        } catch (e) {
            return {'success': false, 'message': 'Không thể kết nối đến máy chủ.'};
        }
    }

    // --- HÀM MỚI ĐỂ CẬP NHẬT USER (BMI) ---
    Future<void> updateUserProfile({
        required String userId,
        double? height,
        double? weight,
        String? gender,
    }) async {
        try {
            // Tạo body chỉ với các trường có dữ liệu
            Map<String, dynamic> body = {};
            if (height != null) body['height'] = height;
            if (weight != null) body['weight'] = weight;
            if (gender != null) body['gender'] = gender;

            final response = await http.put(
                Uri.parse('$_baseUrl/auth/profile/$userId'),
                headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                },
                body: jsonEncode(body),
            );

            if (response.statusCode == 200) {
                // Cập nhật thành công, LƯU LẠI user data mới vào SharedPreferences
                final newUserData = jsonDecode(response.body);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(_userKey, jsonEncode(newUserData));
            } else {
                final body = jsonDecode(response.body);
                throw Exception(body['message'] ?? 'Failed to update profile');
            }
        } catch (e) {
            throw Exception('Không thể kết nối: $e');
        }
    }

    // --- Các hàm quản lý Workout ---
    Future<List<Workout>> getWorkouts() async {
        try {
            final token = await getToken();
            if (token == null) {
                return [];
            }
            
            final response = await http.get(
                Uri.parse('$_baseUrl/calories/history'),
                headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                    'Authorization': 'Bearer $token',
                },
            );

            if (response.statusCode == 200) {
                final body = jsonDecode(response.body);
                if (body['success'] == true && body['data'] is List) {
                    List<dynamic> data = body['data'];
                    List<Workout> workouts = data
                        .map((dynamic item) => Workout.fromJson(item))
                        .toList();
                    return workouts;
                }
                return [];
            } else {
                return [];
            }
        } catch (e) {
            print('Error fetching workouts: $e');
            return [];
        }
    }

    Future<double?> predictCalories(Workout workout) async {
        try {
            final token = await getToken();
            if (token == null) {
                return null;
            }

            final response = await http.post(
                Uri.parse('$_baseUrl/calories/predict'),
                headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                    'Authorization': 'Bearer $token',
                },
                body: jsonEncode({
                    'activityType': workout.activityType,
                    'weight': workout.weight,
                    'height': workout.height,
                    'age': workout.age,
                    'duration': workout.duration,
                    'heartRate': workout.heartRate,
                }),
            );

            if (response.statusCode == 200) {
                final body = jsonDecode(response.body);
                return (body['calories'] as num?)?.toDouble();
            } else {
                return null;
            }
        } catch (e) {
            print('Error predicting calories: $e');
            return null;
        }
    }

    // --- Đổi mật khẩu ---
    Future<Map<String, dynamic>> changePassword({
        required String userId,
        required String oldPassword,
        required String newPassword,
    }) async {
        try {
            final token = await getToken();
            if (token == null) {
                return {'success': false, 'message': 'Chưa đăng nhập'};
            }

            final response = await http.post(
                Uri.parse('$_baseUrl/auth/change-password'),
                headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                    'Authorization': 'Bearer $token',
                },
                body: jsonEncode({
                    'userId': userId,
                    'oldPassword': oldPassword,
                    'newPassword': newPassword,
                }),
            );

            if (response.statusCode == 200) {
                final body = jsonDecode(response.body);
                return {'success': true, 'message': body['message'] ?? 'Đổi mật khẩu thành công'};
            } else {
                final body = jsonDecode(response.body);
                return {'success': false, 'message': body['message'] ?? 'Đổi mật khẩu thất bại'};
            }
        } catch (e) {
            return {'success': false, 'message': 'Không thể kết nối đến máy chủ.'};
        }
    }

    // --- Meals API ---

    // Add meal to server
    Future<Map<String, dynamic>> addMeal({
        required String name,
        required double calories,
        required String mealType,
        required String date,
    }) async {
        try {
            final token = await getToken();
            if (token == null) {
                return {'success': false, 'message': 'Chưa đăng nhập'};
            }

            final response = await http.post(
                Uri.parse('$_baseUrl/meals'),
                headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                    'Authorization': 'Bearer $token',
                },
                body: jsonEncode({
                    'name': name,
                    'calories': calories,
                    'mealType': mealType,
                    'date': date,
                }),
            );

            if (response.statusCode == 201) {
                final body = jsonDecode(response.body);
                return {'success': true, 'message': body['message'] ?? 'Đã lưu bữa ăn'};
            } else {
                final body = jsonDecode(response.body);
                return {'success': false, 'message': body['message'] ?? 'Lưu bữa ăn thất bại'};
            }
        } catch (e) {
            return {'success': false, 'message': 'Không thể kết nối đến máy chủ.'};
        }
    }

    // Get meals for a specific date
    Future<List<Map<String, dynamic>>> getMeals(String date) async {
        try {
            final token = await getToken();
            if (token == null) {
                return [];
            }

            final response = await http.get(
                Uri.parse('$_baseUrl/meals?date=$date'),
                headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                    'Authorization': 'Bearer $token',
                },
            );

            if (response.statusCode == 200) {
                final body = jsonDecode(response.body);
                if (body['success'] == true && body['data'] is List) {
                    return List<Map<String, dynamic>>.from(body['data']);
                }
                return [];
            } else {
                return [];
            }
        } catch (e) {
            print('Error fetching meals: $e');
            return [];
        }
    }

    // Delete a meal
    Future<bool> deleteMeal(String mealId) async {
        try {
            final token = await getToken();
            if (token == null) {
                return false;
            }

            final response = await http.delete(
                Uri.parse('$_baseUrl/meals/$mealId'),
                headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                    'Authorization': 'Bearer $token',
                },
            );

            return response.statusCode == 200;
        } catch (e) {
            print('Error deleting meal: $e');
            return false;
        }
    }

    // --- AI Chat API ---

    Future<String> sendMessageToAI(String message) async {
        try {
            final token = await getToken();
            final userData = await getUserData();
            
            if (token == null || userData == null) {
                throw Exception('Bạn cần đăng nhập để chat với AI');
            }

            final response = await http.post(
                Uri.parse('$_baseUrl/ai/chat'),
                headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                    'Authorization': 'Bearer $token',
                },
                body: jsonEncode({
                    'userId': userData['id'] ?? userData['_id'],
                    'message': message,
                }),
            );

            if (response.statusCode == 200) {
                final body = jsonDecode(response.body);
                return body['reply'] ?? 'Không nhận được phản hồi từ AI';
            } else {
                // In ra lỗi chi tiết từ Backend
                throw Exception('Backend Error [${response.statusCode}]: ${response.body}');
            }
        } catch (e) {
            print('AI Chat Error Trace: $e');
            throw Exception('Lỗi kết nối máy chủ AI: $e');
        }

    }

    // --- AI Health Plan API ---
    Future<Map<String, dynamic>> getHealthPlan() async {
        try {
            final token = await getToken();
            final userData = await getUserData();
            
            if (token == null || userData == null) {
                throw Exception('Bạn cần đăng nhập');
            }

            final response = await http.post(
                Uri.parse('$_baseUrl/ai/generate-plan'),
                headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                    'Authorization': 'Bearer $token',
                },
                body: jsonEncode({
                    'userId': userData['id'] ?? userData['_id'],
                }),
            );

            if (response.statusCode == 200) {
                final body = jsonDecode(response.body);
                return body['data'] ?? {};
            } else {
                throw Exception('Lỗi khi tạo kế hoạch: ${response.statusCode}');
            }
        } catch (e) {
            print('Health Plan Error: $e');
            throw Exception('Không thể kết nối máy chủ: $e');
        }
    }

    // --- AI Vision & Text Analysis ---
    Future<Map<String, dynamic>> analyzeFood({String? text, List<int>? imageBytes, String? fileName}) async {
        try {
            final token = await getToken();
            if (token == null) throw Exception('Chưa đăng nhập');

            var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/ai/analyze-food'));
            request.headers['Authorization'] = 'Bearer $token';

            if (text != null) {
                request.fields['text'] = text;
            }

            if (imageBytes != null) {
                request.files.add(http.MultipartFile.fromBytes(
                    'image',
                    imageBytes,
                    filename: fileName ?? 'food.jpg',
                ));
            }

            final streamedResponse = await request.send();
            final response = await http.Response.fromStream(streamedResponse);

            if (response.statusCode == 200) {
                final body = jsonDecode(response.body);
                return body['data'];
            } else {
                throw Exception('Lỗi phân tích: ${response.statusCode}');
            }
        } catch (e) {
            print('Analyze Food Error: $e');
            throw Exception('Không thể phân tích: $e');
        }
    }
    
    // --- Google Fit Sync ---
    Future<Map<String, dynamic>> syncGoogleFit({required String userId, String? accessToken}) async {
        try {
            final response = await http.post(
                Uri.parse('$_baseUrl/auth/google-sync'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                    'userId': userId,
                    'accessToken': accessToken,
                }),
            );

            if (response.statusCode == 200) {
                return jsonDecode(response.body);
            } else {
                throw Exception('Lỗi đồng bộ Google Fit: ${response.statusCode}');
            }
        } catch (e) {
            print('Google Fit Sync Error: $e');
            throw Exception('Không thể đồng bộ: $e');
        }
    }
}



