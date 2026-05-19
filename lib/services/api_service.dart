import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Sửa lỗi import bằng đường dẫn tương đối
import '../models/workout.dart';

class ApiService {
    static String get _baseUrl {
        final host = Uri.base.host;
        if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
            return 'http://127.0.0.1:3000/api';
        }
        return 'https://calo-backend-api.onrender.com/api';
    }

    static const String _tokenKey = 'authToken';
    static const String _userKey = 'userData';

    // Callback to trigger Riverpod state update on 401
    static void Function()? onUnauthorized;

    // Helper to get authorization headers automatically
    Future<Map<String, String>> _getHeaders({bool isJson = true}) async {
        final token = await getToken();
        final headers = <String, String>{};
        if (isJson) {
            headers['Content-Type'] = 'application/json; charset=UTF-8';
        }
        if (token != null) {
            headers['Authorization'] = 'Bearer $token';
        }
        return headers;
    }

    // Interceptor helper to check for 401 and force logout
    Future<http.Response> _checkResponse(http.Response response) async {
        if (response.statusCode == 401) {
            await logout();
            if (onUnauthorized != null) {
                onUnauthorized!();
            }
            throw Exception('UNAUTHORIZED_ACCESS');
        }
        return response;
    }

    Future<http.Response> _get(String path) async {
        final response = await http.get(Uri.parse('$_baseUrl$path'), headers: await _getHeaders());
        return _checkResponse(response);
    }

    Future<http.Response> _post(String path, dynamic body) async {
        final response = await http.post(
            Uri.parse('$_baseUrl$path'),
            headers: await _getHeaders(),
            body: jsonEncode(body),
        );
        return _checkResponse(response);
    }

    Future<http.Response> _put(String path, dynamic body) async {
        final response = await http.put(
            Uri.parse('$_baseUrl$path'),
            headers: await _getHeaders(),
            body: jsonEncode(body),
        );
        return _checkResponse(response);
    }

    Future<http.Response> _delete(String path) async {
        final response = await http.delete(Uri.parse('$_baseUrl$path'), headers: await _getHeaders());
        return _checkResponse(response);
    }


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

            final response = await _put('/auth/profile/$userId', body);

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
            final response = await _get('/calories/history');

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
            final response = await _post('/calories/predict', {
                'activityType': workout.activityType,
                'weight': workout.weight,
                'height': workout.height,
                'age': workout.age,
                'duration': workout.duration,
                'heartRate': workout.heartRate,
            });

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
            final response = await _post('/auth/change-password', {
                'userId': userId,
                'oldPassword': oldPassword,
                'newPassword': newPassword,
            });

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
        String? imageUrl,
    }) async {
        try {
            final response = await _post('/meals', {
                'name': name,
                'calories': calories,
                'mealType': mealType,
                'date': date,
                'imageUrl': imageUrl ?? '',
            });

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

    // Get meals for a specific date (or all history if date is omitted)
    Future<List<Map<String, dynamic>>> getMeals([String? date]) async {
        try {
            final path = date != null ? '/meals?date=$date' : '/meals';
            final response = await _get(path);

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
            final response = await _delete('/meals/$mealId');
            return response.statusCode == 200;
        } catch (e) {
            print('Error deleting meal: $e');
            return false;
        }
    }

    // --- AI Chat API ---

    Future<Map<String, dynamic>> sendMessageToAI(String message, {String? sessionId}) async {
        try {
            final userData = await getUserData();
            if (userData == null) {
                throw Exception('Bạn cần đăng nhập để chat với AI');
            }

            final bodyData = {
                'userId': userData['id'] ?? userData['_id'],
                'message': message,
            };
            if (sessionId != null) {
                bodyData['sessionId'] = sessionId;
            }

            final response = await _post('/ai/chat', bodyData);

            if (response.statusCode == 200) {
                final body = jsonDecode(response.body);
                return {
                    'reply': body['reply'] ?? 'Không nhận được phản hồi từ AI',
                    'sessionId': body['sessionId'],
                    'sessionTitle': body['sessionTitle'],
                };
            } else {
                throw Exception('Backend Error [${response.statusCode}]: ${response.body}');
            }
        } catch (e) {
            print('AI Chat Error Trace: $e');
            throw Exception('Lỗi kết nối máy chủ AI: $e');
        }
    }

    // --- Lấy danh sách phiên chat ---
    Future<List<Map<String, dynamic>>> getChatSessions() async {
        try {
            final userData = await getUserData();
            if (userData == null) throw Exception('Chưa đăng nhập');

            final userId = userData['id'] ?? userData['_id'];
            final response = await _get('/ai/sessions?userId=$userId');

            if (response.statusCode == 200) {
                final body = jsonDecode(response.body);
                if (body['success'] == true && body['sessions'] != null) {
                    return List<Map<String, dynamic>>.from(body['sessions']);
                }
                return [];
            } else {
                throw Exception('Lỗi lấy danh sách phiên chat: ${response.statusCode}');
            }
        } catch (e) {
            print('getChatSessions Error: $e');
            return [];
        }
    }

    // --- Lấy chi tiết phiên chat ---
    Future<Map<String, dynamic>> getChatSessionDetail(String sessionId) async {
        try {
            final response = await _get('/ai/sessions/$sessionId');

            if (response.statusCode == 200) {
                final body = jsonDecode(response.body);
                return body;
            } else {
                throw Exception('Lỗi lấy chi tiết phiên chat: ${response.statusCode}');
            }
        } catch (e) {
            print('getChatSessionDetail Error: $e');
            throw Exception('Không thể tải chi tiết phiên chat: $e');
        }
    }

    // --- Tạo mới phiên chat trống ---
    Future<Map<String, dynamic>> createChatSession() async {
        try {
            final userData = await getUserData();
            if (userData == null) throw Exception('Chưa đăng nhập');

            final userId = userData['id'] ?? userData['_id'];
            final response = await _post('/ai/sessions', {
                'userId': userId,
            });

            if (response.statusCode == 201 || response.statusCode == 200) {
                return jsonDecode(response.body);
            } else {
                throw Exception('Lỗi tạo phiên chat: ${response.statusCode}');
            }
        } catch (e) {
            print('createChatSession Error: $e');
            throw Exception('Không thể tạo phiên chat mới: $e');
        }
    }

    // --- Xóa phiên chat ---
    Future<bool> deleteChatSession(String sessionId) async {
        try {
            final headers = await _getHeaders(isJson: true);
            final response = await http.delete(
                Uri.parse('$_baseUrl/ai/sessions/$sessionId'),
                headers: headers,
            );

            if (response.statusCode == 200) {
                return true;
            } else {
                throw Exception('Lỗi xóa phiên chat: ${response.statusCode}');
            }
        } catch (e) {
            print('deleteChatSession Error: $e');
            throw Exception('Không thể xóa phiên chat: $e');
        }
    }

    // --- AI Health Plan API ---
    Future<Map<String, dynamic>> getHealthPlan({String? allergies}) async {
        try {
            final userData = await getUserData();
            if (userData == null) {
                throw Exception('Bạn cần đăng nhập');
            }

            final body = <String, dynamic>{
                'userId': userData['id'] ?? userData['_id'],
            };
            if (allergies != null && allergies.isNotEmpty) {
                body['userInput'] = allergies;
            }

            final response = await _post('/ai/plan', body);

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
    Future<Map<String, dynamic>> analyzeFood({
        String? text,
        List<int>? imageBytes,
        String? fileName,
        double? remainingCalories,
        double? todayIntake,
        double? targetCalories,
    }) async {
        try {
            var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/ai/analyze-food'));
            final tokenHeaders = await _getHeaders(isJson: false);
            request.headers.addAll(tokenHeaders);

            if (text != null) {
                request.fields['text'] = text;
            }
            if (remainingCalories != null) {
                request.fields['remainingCalories'] = remainingCalories.toString();
            }
            if (todayIntake != null) {
                request.fields['todayIntake'] = todayIntake.toString();
            }
            if (targetCalories != null) {
                request.fields['targetCalories'] = targetCalories.toString();
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
            await _checkResponse(response);

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

    // --- Log Workout directly ---
    Future<Map<String, dynamic>> logWorkout({
        required String activityName,
        required double duration,
        required double caloriesBurned,
    }) async {
        try {
            final headers = await _getHeaders(isJson: true);
            final response = await http.post(
                Uri.parse('$_baseUrl/calories/add'),
                headers: headers,
                body: jsonEncode({
                    'activityName': activityName,
                    'duration': duration,
                    'caloriesBurned': caloriesBurned,
                }),
            );

            if (response.statusCode == 200 || response.statusCode == 201) {
                return jsonDecode(response.body);
            } else {
                final body = jsonDecode(response.body);
                throw Exception(body['message'] ?? 'Lỗi lưu hoạt động');
            }
        } catch (e) {
            print('Log Workout Error: $e');
            throw Exception('Không thể lưu hoạt động: $e');
        }
    }

    // --- Cập nhật thông tin chiều cao, cân nặng, giới tính ---
    Future<Map<String, dynamic>> updateProfile({
        required double height,
        required double weight,
        required String gender,
        required int age,
    }) async {
        try {
            final userData = await getUserData();
            if (userData == null) throw Exception('Chưa đăng nhập');

            final userId = userData['id'] ?? userData['_id'];
            final headers = await _getHeaders(isJson: true);
            final response = await http.put(
                Uri.parse('$_baseUrl/auth/profile/$userId'),
                headers: headers,
                body: jsonEncode({
                    'height': height,
                    'weight': weight,
                    'gender': gender,
                    'age': age,
                }),
            );

            if (response.statusCode == 200) {
                final body = jsonDecode(response.body);
                // Cập nhật lại dữ liệu user lưu trong cache SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                final currentToken = prefs.getString(_tokenKey) ?? '';
                await _saveAuthData(currentToken, body);
                return {'success': true, 'user': body};
            } else {
                throw Exception('Lỗi cập nhật: ${response.statusCode}');
            }
        } catch (e) {
            print('updateProfile Error: $e');
            return {'success': false, 'message': e.toString()};
        }
    }

    // --- Gửi đóng góp ý kiến ---
    Future<Map<String, dynamic>> submitFeedback({
        required String content,
    }) async {
        try {
            final response = await _post('/feedback/submit', {
                'content': content,
            });

            if (response.statusCode == 200) {
                final body = jsonDecode(response.body);
                return {'success': true, 'message': body['message'] ?? 'Gửi phản hồi thành công'};
            } else {
                final body = jsonDecode(response.body);
                return {'success': false, 'message': body['message'] ?? 'Gửi phản hồi thất bại'};
            }
        } catch (e) {
            return {'success': false, 'message': 'Không thể kết nối đến máy chủ.'};
        }
    }
}



