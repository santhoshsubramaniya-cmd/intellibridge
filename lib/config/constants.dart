class AppConstants {
  static const appName = 'InteliBridge';
  static const appTagline = 'Campus to Career — Powered by AI';

  // Roles
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

  static const semesters = [1, 2, 3, 4, 5, 6];

  static const allSkills = [
    'Python', 'Java', 'JavaScript', 'C++', 'C', 'SQL', 'R', 'Go',
    'HTML/CSS', 'React', 'Node.js', 'Flask', 'Django', 'Spring Boot',
    'Machine Learning', 'Deep Learning', 'TensorFlow', 'Data Analysis',
    'Excel', 'Power BI', 'Tableau', 'Git', 'Docker', 'Kubernetes',
    'AWS', 'Azure', 'Linux', 'DSA', 'System Design', 'REST APIs',
  ];

  static const roleSkills = {
    'Software Engineer': ['Python', 'Java', 'DSA', 'System Design', 'Git', 'REST APIs'],
    'Data Analyst': ['Python', 'SQL', 'Excel', 'Power BI', 'Tableau'],
    'Data Scientist': ['Python', 'Machine Learning', 'Deep Learning', 'SQL', 'TensorFlow'],
    'Frontend Developer': ['HTML/CSS', 'JavaScript', 'React', 'Git'],
    'Backend Developer': ['Python', 'Node.js', 'REST APIs', 'SQL', 'Docker'],
    'Full Stack Developer': ['HTML/CSS', 'JavaScript', 'React', 'Node.js', 'SQL'],
    'DevOps Engineer': ['Linux', 'Docker', 'Kubernetes', 'AWS', 'Git'],
    'Business Analyst': ['Excel', 'SQL', 'Power BI', 'Data Analysis'],
  };

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
