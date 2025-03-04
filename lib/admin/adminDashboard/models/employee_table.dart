class EmployeesApi {
  static Future<List<Map<String, String>>> fetchEmployees() async {
    await Future.delayed(const Duration(seconds: 2));

  //   static Future<List<Map<String, String>>> fetchEmployees() async {
  //   String url = 'https://api.neophyte.live/hrms-api/api/employees'; 
  //   try {
  //     final response = await http.get(Uri.parse(url));

  //     if (response.statusCode == 200) {
  //       List<dynamic> employeesJson = jsonDecode(response.body);

  //       List<Map<String, String>> employees = employeesJson.map((employee) {
  //         return {
  //           "id": employee["id"].toString(),
  //           "image": employee["profile_image"] ?? "https://via.placeholder.com/50",
  //           "name": employee["name"] ?? "N/A",
  //           "email": employee["email"] ?? "N/A",
  //         };
  //       }).toList();

  //       return employees;
  //     } else {
  //       throw Exception("Failed to load employees");
  //     }
  //   } catch (e) {
  //     throw Exception("Error fetching employees: $e");
  //   }
  // }
    // Dummy employee data
    List<Map<String, String>> employees = [
      {
        "id": "1",
        "image": "https://via.placeholder.com/50",
        "name": "John Doe",
        "email": "john.doe@example.com"
      },
      {
        "id": "2",
        "image": "https://via.placeholder.com/50",
        "name": "Jane Smith",
        "email": "jane.smith@example.com"
      },
      {
        "id": "3",
        "image": "https://via.placeholder.com/50",
        "name": "Robert Johnson",
        "email": "robert.johnson@example.com"
      },
      {
        "id": "4",
        "image": "https://via.placeholder.com/50",
        "name": "Emily Davis",
        "email": "emily.davis@example.com"
      },
      {
        "id": "5",
        "image": "https://via.placeholder.com/50",
        "name": "Michael Brown",
        "email": "michael.brown@example.com"
      },
    ];

    return employees;
  }
}
