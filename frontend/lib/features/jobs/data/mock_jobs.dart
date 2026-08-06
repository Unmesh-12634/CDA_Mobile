class Job {
  final String id;
  final String title;
  final String company;
  final String location;
  final String type; // e.g. Full-time, Remote, Hybrid
  final String salary;
  final String logoText;
  final String category; // e.g. Tech, Product, AI & ML, Design
  final int matchScore; // e.g. 95%
  final String postedAgo;
  final String experienceLevel;
  final String description;
  final List<String> responsibilities;
  final List<String> requirements;
  final List<String> tags;

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.type,
    required this.salary,
    required this.logoText,
    required this.category,
    required this.matchScore,
    required this.postedAgo,
    required this.experienceLevel,
    required this.description,
    required this.responsibilities,
    required this.requirements,
    required this.tags,
  });
}

final List<Job> sampleJobs = [
  const Job(
    id: 'job-101',
    title: 'Senior Frontend Engineer (Flutter/React)',
    company: 'Linear App',
    location: 'Remote • San Francisco, CA',
    type: 'Full-time',
    salary: '\$140,000 - \$180,000 / yr',
    logoText: 'LN',
    category: 'Tech',
    matchScore: 98,
    postedAgo: '2 hours ago',
    experienceLevel: 'Senior (4+ yrs)',
    description:
        'Linear is building the next-generation issue tracking and product development platform. We are seeking a Staff/Senior Frontend Specialist with strong expertise in Flutter, React, dynamic state management, and high-performance mobile/web UIs.',
    responsibilities: [
      'Architect and build sleek, ultra-responsive cross-platform interfaces.',
      'Collaborate directly with product design and core engineering teams.',
      'Optimize app runtime performance, state management, and render trees.',
      'Mentor junior engineers and champion clean code standards.',
    ],
    requirements: [
      '4+ years of professional software development experience.',
      'Deep proficiency in Dart/Flutter, React, and modern UI architectures.',
      'Strong grasp of state management (Riverpod, Bloc, or Redux).',
      'Track record of building polished, consumer-facing mobile/web apps.',
    ],
    tags: ['Flutter', 'React', 'Remote', 'TypeScript', 'UI/UX'],
  ),
  const Job(
    id: 'job-102',
    title: 'AI Product Manager (LLM & Agentic Systems)',
    company: 'Anthropic Tech',
    location: 'Hybrid • New York, NY',
    type: 'Full-time',
    salary: '\$160,000 - \$210,000 / yr',
    logoText: 'AN',
    category: 'Product',
    matchScore: 94,
    postedAgo: '5 hours ago',
    experienceLevel: 'Mid-Senior (3+ yrs)',
    description:
        'Lead product strategy for cutting-edge generative AI assistants, automated workflow builders, and enterprise LLM integrations. Work alongside world-class AI researchers to transform novel models into intuitive user products.',
    responsibilities: [
      'Define product roadmaps, user personas, and core metrics for AI features.',
      'Conduct user interviews, market research, and competitive benchmarks.',
      'Partner with ML research teams to integrate novel model capabilities.',
      'Drive product launch strategy, GTM execution, and user feedback loops.',
    ],
    requirements: [
      '3+ years in Product Management for AI, ML, or developer tool products.',
      'Solid understanding of LLMs, prompt architecture, and RAG systems.',
      'Data-driven mindset with analytical skill in SQL and product analytics.',
    ],
    tags: ['AI/ML', 'Product Strategy', 'LLM', 'RAG', 'Generative AI'],
  ),
  const Job(
    id: 'job-103',
    title: 'Lead System Architect / Backend Lead',
    company: 'Stripe Payments',
    location: 'Remote • Austin, TX',
    type: 'Full-time',
    salary: '\$175,000 - \$230,000 / yr',
    logoText: 'ST',
    category: 'Tech',
    matchScore: 91,
    postedAgo: '1 day ago',
    experienceLevel: 'Lead (6+ yrs)',
    description:
        'Design ultra-scalable distributed backend infrastructure processing billions in global payment volume. Build resilient microservices, payment gateways, and fault-tolerant APIs.',
    responsibilities: [
      'Design high-throughput, low-latency microservices handling 10k+ QPS.',
      'Optimize database schemas, caching layers, and asynchronous queues.',
      'Implement strict security compliance, data encryption, and audit protocols.',
    ],
    requirements: [
      '6+ years backend engineering with Go, Java, or Python.',
      'Deep expertise in distributed systems, PostgreSQL, Redis, and Kafka.',
      'Proven expertise with AWS or GCP Cloud Infrastructure.',
    ],
    tags: ['System Design', 'Go', 'Distributed Systems', 'GCP', 'PostgreSQL'],
  ),
  const Job(
    id: 'job-104',
    title: 'Senior Product Designer (Mobile & Web)',
    company: 'Figma Design',
    location: 'Remote • San Francisco, CA',
    type: 'Full-time',
    salary: '\$135,000 - \$170,000 / yr',
    logoText: 'FG',
    category: 'Design',
    matchScore: 88,
    postedAgo: '2 days ago',
    experienceLevel: 'Senior (4+ yrs)',
    description:
        'Shape the future of modern design tools. We are looking for a Senior Product Designer to craft intuitive, delightful, and highly performant web and mobile interaction patterns.',
    responsibilities: [
      'Design end-to-end interactive prototypes, wireframes, and design tokens.',
      'Maintain and expand design system components across mobile & web.',
      'Conduct usability studies and synthesize insights into product improvements.',
    ],
    requirements: [
      '4+ years UX/UI Product Design experience.',
      'Mastery of Figma, design systems, glassmorphism, and micro-animations.',
      'Strong portfolio showcasing mobile & web product design execution.',
    ],
    tags: ['UI/UX', 'Design Systems', 'Figma', 'Prototyping'],
  ),
  const Job(
    id: 'job-105',
    title: 'Cloud DevOps & Infrastructure Engineer',
    company: 'Google Cloud Platform',
    location: 'Hybrid • Seattle, WA',
    type: 'Full-time',
    salary: '\$150,000 - \$195,000 / yr',
    logoText: 'GC',
    category: 'Tech',
    matchScore: 86,
    postedAgo: '3 days ago',
    experienceLevel: 'Mid-Senior (3+ yrs)',
    description:
        'Build automated CI/CD deployment pipelines, manage Kubernetes clusters, and optimize cloud infrastructure security and observability for multi-region cloud services.',
    responsibilities: [
      'Manage Infrastructure as Code using Terraform and Kubernetes.',
      'Optimize CI/CD build speeds, automated test integration, and blue-green deployments.',
      'Monitor telemetry, uptime, and incident resolution protocols.',
    ],
    requirements: [
      '3+ years DevOps or SRE experience with Docker & Kubernetes.',
      'Proficiency in Terraform, GCP / AWS, Bash, and Python.',
      'Solid understanding of Linux networking, security, and IAM.',
    ],
    tags: ['DevOps', 'Kubernetes', 'GCP', 'Terraform', 'CI/CD'],
  ),
];
