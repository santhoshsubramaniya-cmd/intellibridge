class AppConstants {
  // App info
  static const appName = 'SmartPlace';
  static const appTagline = 'Campus to Career — Powered by AI';
  static const appVersion = '1.0.0';

  // User roles
  static const roleStudent = 'student';
  static const roleFaculty = 'faculty';
  static const roleAdmin = 'admin';
  static const roleRecruiter = 'recruiter';

  // Courses (from Smart Campus)
  static const courses = [
    'BSC COMPUTER SCIENCE',
    'BCOM',
    'BSC ELECTRONICS',
    'BCA',
  ];

  // Semesters
  static const semesters = [1, 2, 3, 4, 5, 6];

  // Skills list
  static const allSkills = [
    'Python', 'Java', 'JavaScript', 'C++', 'C',
    'SQL', 'R', 'Go', 'HTML/CSS', 'React',
    'Node.js', 'Flask', 'Django', 'Spring Boot',
    'Machine Learning', 'Deep Learning', 'TensorFlow',
    'Data Analysis', 'Excel', 'Power BI', 'Tableau',
    'Git', 'Docker', 'Kubernetes', 'AWS', 'Azure',
    'Linux', 'DSA', 'System Design', 'REST APIs',
  ];

  // Role to required skills mapping
  static const roleSkills = {
    'Software Engineer': ['Python', 'Java', 'DSA', 'System Design', 'Git'],
    'Data Analyst': ['Python', 'SQL', 'Excel', 'Power BI', 'Tableau'],
    'Data Scientist': ['Python', 'Machine Learning', 'Deep Learning', 'SQL'],
    'Frontend Developer': ['HTML/CSS', 'JavaScript', 'React', 'Git'],
    'Backend Developer': ['Python', 'Node.js', 'REST APIs', 'SQL', 'Docker'],
    'Full Stack Developer': ['HTML/CSS', 'JavaScript', 'React', 'Node.js', 'SQL'],
    'DevOps Engineer': ['Linux', 'Docker', 'Kubernetes', 'AWS', 'Git'],
    'Business Analyst': ['Excel', 'SQL', 'Power BI', 'Data Analysis'],
  };

  // Subject to skill mapping (Smart Campus integration)
  static const subjectToSkill = {
    'Database Management': ['SQL', 'MySQL'],
    'Machine Learning': ['Python', 'Machine Learning', 'TensorFlow'],
    'Web Technologies': ['HTML/CSS', 'JavaScript', 'Flask'],
    'Data Structures': ['DSA', 'Java', 'C++'],
    'Computer Networks': ['Linux', 'AWS'],
    'Python Programming': ['Python', 'Flask', 'Django'],
    'Java Programming': ['Java', 'Spring Boot'],
    'Cloud Computing': ['AWS', 'Azure', 'Docker'],
  };

  // Firestore collections
  static const colUsers = 'users';
  static const colStudents = 'students';
  static const colFaculty = 'faculty';
  static const colNotes = 'notes';
  static const colResults = 'results';
  static const colAnnouncements = 'announcements';
  static const colJobs = 'jobs';
  static const colApplications = 'applications';
  static const colDrives = 'placement_drives';
  static const colAlerts = 'alerts';
  static const colMessages = 'messages';
  static const colTrainingPlans = 'training_plans';
  static const colPercentiles = 'percentiles';
}
