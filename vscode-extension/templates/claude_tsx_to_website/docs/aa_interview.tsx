import React, { useState } from 'react';

const Dashboard = () => {
  const [activeTab, setActiveTab] = useState('overview');

  const handleTabChange = (tab) => {
    setActiveTab(tab);
  };

  return (
    <div className="bg-slate-50 min-h-screen p-6">
      <header className="bg-blue-900 text-white p-4 rounded-lg shadow-md mb-6">
        <h1 className="text-2xl font-bold">American Airlines Data Scientist Interview Preparation</h1>
        <p className="text-lg font-light">Req 78278: Data Scientist/Sr Data Scientist, IT Operations Research and Advanced Analytics</p>
      </header>

      {/* Navigation Tabs */}
      <div className="mb-6 bg-white rounded-lg shadow-md overflow-hidden">
        <div className="flex border-b">
          <button 
            className={`px-4 py-3 text-sm font-medium flex-1 ${activeTab === 'overview' ? 'bg-blue-100 text-blue-900 border-b-2 border-blue-900' : 'text-gray-700'}`}
            onClick={() => handleTabChange('overview')}
          >
            Executive Summary
          </button>
          <button 
            className={`px-4 py-3 text-sm font-medium flex-1 ${activeTab === 'role' ? 'bg-blue-100 text-blue-900 border-b-2 border-blue-900' : 'text-gray-700'}`}
            onClick={() => handleTabChange('role')}
          >
            Role Analysis
          </button>
          <button 
            className={`px-4 py-3 text-sm font-medium flex-1 ${activeTab === 'interviewer' ? 'bg-blue-100 text-blue-900 border-b-2 border-blue-900' : 'text-gray-700'}`}
            onClick={() => handleTabChange('interviewer')}
          >
            Interviewer Profile
          </button>
          <button 
            className={`px-4 py-3 text-sm font-medium flex-1 ${activeTab === 'technical' ? 'bg-blue-100 text-blue-900 border-b-2 border-blue-900' : 'text-gray-700'}`}
            onClick={() => handleTabChange('technical')}
          >
            Technical Domains
          </button>
          <button 
            className={`px-4 py-3 text-sm font-medium flex-1 ${activeTab === 'applications' ? 'bg-blue-100 text-blue-900 border-b-2 border-blue-900' : 'text-gray-700'}`}
            onClick={() => handleTabChange('applications')}
          >
            Application Areas
          </button>
          <button 
            className={`px-4 py-3 text-sm font-medium flex-1 ${activeTab === 'strategy' ? 'bg-blue-100 text-blue-900 border-b-2 border-blue-900' : 'text-gray-700'}`}
            onClick={() => handleTabChange('strategy')}
          >
            Interview Strategy
          </button>
        </div>

        {/* Executive Summary Tab */}
        {activeTab === 'overview' && (
          <div className="p-6">
            <h2 className="text-xl font-bold text-blue-900 mb-4">Key Success Factors</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
              <div className="bg-white p-4 rounded-lg border-l-4 border-blue-600 shadow">
                <h3 className="font-semibold text-lg text-blue-900 mb-2">LLM Development Expertise</h3>
                <p className="text-gray-700">Hands-on experience with the complete Large Language Model lifecycle, including Retrieval-Augmented Generation (RAG) and Prompt Engineering</p>
              </div>
              <div className="bg-white p-4 rounded-lg border-l-4 border-green-600 shadow">
                <h3 className="font-semibold text-lg text-green-900 mb-2">Cloud Platform Proficiency</h3>
                <p className="text-gray-700">Strong focus on Microsoft Azure and its AI ecosystem, particularly Azure AI Foundry</p>
              </div>
              <div className="bg-white p-4 rounded-lg border-l-4 border-purple-600 shadow">
                <h3 className="font-semibold text-lg text-purple-900 mb-2">Data Science & ML Foundation</h3>
                <p className="text-gray-700">Solid grasp of core principles, potentially augmented by Operations Research concepts relevant to IT operations</p>
              </div>
              <div className="bg-white p-4 rounded-lg border-l-4 border-orange-600 shadow">
                <h3 className="font-semibold text-lg text-orange-900 mb-2">Technical Stack Familiarity</h3>
                <p className="text-gray-700">Strong Python skills and familiarity with Vector Databases (Pinecone, FAISS, Weaviate) and MLOps tools</p>
              </div>
            </div>
            
            <div className="bg-gray-100 p-4 rounded-lg mb-6">
              <h3 className="font-semibold text-lg mb-2">Role Context</h3>
              <p className="text-gray-700 mb-4">This position sits within the IT Operations Research and Advanced Analytics (OR&AA) Gen AI team at American Airlines.</p>
              <p className="text-gray-700">The primary application domain is likely <span className="font-semibold">internal IT operations</span>, focusing on optimizing IT infrastructure, automating support processes, enhancing cybersecurity analytics, or streamlining operational workflows using AI/ML techniques.</p>
            </div>
            
            <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
              <h3 className="font-semibold text-lg text-blue-900 mb-2">Strategic Approach</h3>
              <p className="text-gray-700">Align experiences with AA's apparent focus on practical, scalable, and reliable AI solutions, potentially reflecting the interviewer's background in Reliability Engineering</p>
            </div>
          </div>
        )}

        {/* Role Analysis Tab */}
        {activeTab === 'role' && (
          <div className="p-6">
            <h2 className="text-xl font-bold text-blue-900 mb-4">Role Analysis: Data Scientist/Sr Data Scientist (Req 78278)</h2>
            
            <div className="bg-blue-50 p-4 rounded-lg border border-blue-200 mb-6">
              <h3 className="font-semibold text-lg text-blue-900 mb-2">Core Responsibilities</h3>
              <ul className="list-disc pl-6 space-y-2 text-gray-700">
                <li>Involvement across the entire AI solution lifecycle</li>
                <li>Collaboration with diverse stakeholders (business leaders, analysts, project managers)</li>
                <li>Data handling: obtaining, manipulating, cleaning, and analyzing data</li>
                <li>Researching and implementing new AI technologies</li>
                <li>Building and validating analytical/statistical models</li>
                <li>Collaborating with ML Engineers for model deployment</li>
                <li>Monitoring deployed models and quantifying business impact</li>
              </ul>
            </div>
            
            <div className="bg-green-50 p-4 rounded-lg border border-green-200 mb-6">
              <h3 className="font-semibold text-lg text-green-900 mb-2">Generative AI Focus</h3>
              <ul className="list-disc pl-6 space-y-2 text-gray-700">
                <li>Developing/implementing generative AI solutions using LLMs (OpenAI GPT, Google Gemini, Llama)</li>
                <li>Expertise in Prompt Engineering</li>
                <li>Knowledge of Vector Databases (Pinecone, FAISS, Weaviate)</li>
                <li>Experience with Retrieval-Augmented Generation (RAG)</li>
              </ul>
            </div>
            
            <h3 className="text-lg font-bold text-blue-900 mb-3">Technical Skills Requirements</h3>
            <div className="overflow-x-auto">
              <table className="min-w-full bg-white border border-gray-300 rounded-lg">
                <thead>
                  <tr className="bg-blue-900 text-white">
                    <th className="py-2 px-4 border-b text-left">Skill Category</th>
                    <th className="py-2 px-4 border-b text-left">Specific Skills/Tools</th>
                    <th className="py-2 px-4 border-b text-left">Requirement Level</th>
                  </tr>
                </thead>
                <tbody>
                  <tr className="bg-blue-50">
                    <td className="py-2 px-4 border-b font-medium">Programming</td>
                    <td className="py-2 px-4 border-b">Python</td>
                    <td className="py-2 px-4 border-b">Required Proficiency</td>
                  </tr>
                  <tr>
                    <td className="py-2 px-4 border-b"></td>
                    <td className="py-2 px-4 border-b">Java, R</td>
                    <td className="py-2 px-4 border-b">Experience with at least one</td>
                  </tr>
                  <tr className="bg-blue-50">
                    <td className="py-2 px-4 border-b font-medium">Cloud Platforms</td>
                    <td className="py-2 px-4 border-b">Microsoft Azure (Azure AI Foundry, Azure ML), AWS</td>
                    <td className="py-2 px-4 border-b">Cloud-based development required</td>
                  </tr>
                  <tr>
                    <td className="py-2 px-4 border-b font-medium">ML Frameworks</td>
                    <td className="py-2 px-4 border-b">TensorFlow, PyTorch, Keras, Scikit-learn, Hugging Face</td>
                    <td className="py-2 px-4 border-b">AI/ML Frameworks proficiency</td>
                  </tr>
                  <tr className="bg-blue-50">
                    <td className="py-2 px-4 border-b font-medium">GenAI / LLM</td>
                    <td className="py-2 px-4 border-b">LLMs (OpenAI GPT, Google Gemini, Llama), RAG, Prompt Engineering, NLP Concepts</td>
                    <td className="py-2 px-4 border-b">Experience developing/implementing</td>
                  </tr>
                  <tr>
                    <td className="py-2 px-4 border-b font-medium">Vector Databases</td>
                    <td className="py-2 px-4 border-b">Pinecone, FAISS, Weaviate</td>
                    <td className="py-2 px-4 border-b">Knowledge required</td>
                  </tr>
                  <tr className="bg-blue-50">
                    <td className="py-2 px-4 border-b font-medium">MLOps / DevOps</td>
                    <td className="py-2 px-4 border-b">MLflow, Kubeflow, Airflow, Docker, Kubernetes, Git, Jenkins, CI/CD, ADO Pipelines</td>
                    <td className="py-2 px-4 border-b">MLOps/DevOps Toolchain Experience</td>
                  </tr>
                  <tr>
                    <td className="py-2 px-4 border-b font-medium">Databases</td>
                    <td className="py-2 px-4 border-b">Oracle, Hibernate, O/RM, Query Tuning, SQL (implied)</td>
                    <td className="py-2 px-4 border-b">Database framework experience</td>
                  </tr>
                  <tr className="bg-blue-50">
                    <td className="py-2 px-4 border-b font-medium">Core DS/ML</td>
                    <td className="py-2 px-4 border-b">Statistical & ML Techniques, Data Extraction/Cleaning/Analysis, Forecasting, CV, NLP</td>
                    <td className="py-2 px-4 border-b">Deep knowledge, Practical experience</td>
                  </tr>
                  <tr>
                    <td className="py-2 px-4 border-b font-medium">Methodologies</td>
                    <td className="py-2 px-4 border-b">Agile (SCRUM)</td>
                    <td className="py-2 px-4 border-b">Experience required</td>
                  </tr>
                  <tr className="bg-blue-50">
                    <td className="py-2 px-4 border-b font-medium">Experience</td>
                    <td className="py-2 px-4 border-b">3+ years designing, building, deploying ML models (DL, NLP, CV, RecSys, A/B testing)</td>
                    <td className="py-2 px-4 border-b">Preferred</td>
                  </tr>
                  <tr>
                    <td className="py-2 px-4 border-b font-medium">Industry Experience</td>
                    <td className="py-2 px-4 border-b">Airline Industry</td>
                    <td className="py-2 px-4 border-b">Preferred</td>
                  </tr>
                </tbody>
              </table>
            </div>
            
            <div className="mt-6 bg-gray-100 p-4 rounded-lg">
              <h3 className="font-semibold text-lg mb-2">Team Context: "IT Operations Research and Advanced Analytics"</h3>
              <p className="text-gray-700 mb-2">The unique blend of "Gen AI," "IT Operations," and "Operations Research" suggests AA seeks individuals capable of:</p>
              <ul className="list-disc pl-6 space-y-1 text-gray-700">
                <li>Building sophisticated GenAI models for specific operational contexts</li>
                <li>Leveraging OR principles to optimize AI deployment</li>
                <li>Integrating AI with existing OR-based systems</li>
                <li>Understanding how AI can enhance or solve operational problems within IT</li>
              </ul>
            </div>
          </div>
        )}

        {/* Interviewer Profile Tab */}
        {activeTab === 'interviewer' && (
          <div className="p-6">
            <h2 className="text-xl font-bold text-blue-900 mb-4">Interviewer Profile: Varun Khemani, PhD</h2>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
              <div className="bg-white p-4 rounded-lg shadow">
                <h3 className="font-semibold text-lg text-blue-900 mb-2">Academic Background</h3>
                <ul className="list-disc pl-6 space-y-1 text-gray-700">
                  <li>PhD in Reliability Engineering (University of Maryland)</li>
                  <li>Master's in Industrial Engineering (North Carolina State University)</li>
                  <li>Focus on Design of Experiments (DOE)</li>
                </ul>
              </div>
              <div className="bg-white p-4 rounded-lg shadow">
                <h3 className="font-semibold text-lg text-blue-900 mb-2">Professional Position</h3>
                <ul className="list-disc pl-6 space-y-1 text-gray-700">
                  <li>Senior Data Scientist, OR&AA group (IT organization)</li>
                  <li>Previously: Predictive Maintenance Data Scientist (late 2022)</li>
                  <li>Works within historically impactful analytics team</li>
                </ul>
              </div>
            </div>
            
            <div className="bg-blue-50 p-4 rounded-lg border border-blue-200 mb-6">
              <h3 className="font-semibold text-lg text-blue-900 mb-2">Areas of Expertise</h3>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
                <div className="bg-white p-3 rounded border border-blue-200 text-center">
                  <span className="block text-blue-900 font-medium">Data Science</span>
                </div>
                <div className="bg-white p-3 rounded border border-blue-200 text-center">
                  <span className="block text-blue-900 font-medium">AI/ML</span>
                </div>
                <div className="bg-white p-3 rounded border border-blue-200 text-center">
                  <span className="block text-blue-900 font-medium">Operations Research</span>
                </div>
                <div className="bg-white p-3 rounded border border-blue-200 text-center">
                  <span className="block text-blue-900 font-medium">Stochastic Optimization</span>
                </div>
                <div className="bg-white p-3 rounded border border-blue-200 text-center">
                  <span className="block text-blue-900 font-medium">Reliability Engineering</span>
                </div>
                <div className="bg-white p-3 rounded border border-blue-200 text-center">
                  <span className="block text-blue-900 font-medium">Cybersecurity</span>
                </div>
              </div>
            </div>
            
            <div className="bg-green-50 p-4 rounded-lg border border-green-200 mb-6">
              <h3 className="font-semibold text-lg text-green-900 mb-2">Research Focus</h3>
              <p className="text-gray-700 mb-3">Prominent focus on <span className="font-medium">Predictive Maintenance (PdM)</span> or Prognostics and Health Management (PHM), especially for electronic systems:</p>
              <ul className="list-disc pl-6 space-y-1 text-gray-700">
                <li>Previous title explicitly mentioned Predictive Maintenance</li>
                <li>Presented on OR/ML applications at AA, including predictive maintenance</li>
                <li>Co-taught on advanced AI/ML for diagnostics and prognostics</li>
                <li>Published on electronic circuit diagnosis/health estimation</li>
                <li>Work on secure health management of electronic systems</li>
              </ul>
            </div>
            
            <div className="bg-purple-50 p-4 rounded-lg border border-purple-200">
              <h3 className="font-semibold text-lg text-purple-900 mb-2">Potential Interview Focus</h3>
              <ul className="list-disc pl-6 space-y-2 text-gray-700">
                <li><span className="font-medium">Fundamental Understanding:</span> Testing knowledge beyond surface-level, probing the 'why' and 'how' behind algorithms and techniques</li>
                <li><span className="font-medium">Reliability & Robustness:</span> Emphasis on solutions that are accurate, robust, reliable, scalable, and maintainable over time</li>
                <li><span className="font-medium">Business Impact:</span> Focus on solving tangible business problems and quantifying the impact of technical solutions</li>
                <li><span className="font-medium">OR Integration:</span> Appreciation for awareness of Operations Research concepts and optimization mindset</li>
                <li><span className="font-medium">IT System Reliability:</span> Potential interest in applying GenAI/ML to improve reliability, diagnostics, or health management of AA's IT infrastructure</li>
              </ul>
            </div>
          </div>
        )}

        {/* Technical Domains Tab */}
        {activeTab === 'technical' && (
          <div className="p-6">
            <h2 className="text-xl font-bold text-blue-900 mb-4">Key Technical Domains for Pre-Screening</h2>
            
            <div className="bg-blue-50 p-5 rounded-lg border border-blue-200 mb-6">
              <h3 className="font-semibold text-lg text-blue-900 mb-3">Generative AI & LLMs</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="bg-white p-3 rounded shadow">
                  <h4 className="font-medium text-blue-800 mb-2">Foundational Concepts</h4>
                  <ul className="list-disc pl-5 space-y-1 text-gray-700 text-sm">
                    <li>Transformers architecture</li>
                    <li>Embeddings & vectors</li>
                    <li>Attention mechanisms</li>
                    <li>Tokenization</li>
                    <li>Differences between major model families</li>
                  </ul>
                </div>
                <div className="bg-white p-3 rounded shadow">
                  <h4 className="font-medium text-blue-800 mb-2">Development Lifecycle</h4>
                  <ul className="list-disc pl-5 space-y-1 text-gray-700 text-sm">
                    <li>Prompt Engineering</li>
                    <li>Retrieval-Augmented Generation (RAG)</li>
                    <li>Fine-tuning concepts</li>
                    <li>Model evaluation metrics</li>
                  </ul>
                </div>
                <div className="bg-white p-3 rounded shadow">
                  <h4 className="font-medium text-blue-800 mb-2">RAG Deep Dive</h4>
                  <ul className="list-disc pl-5 space-y-1 text-gray-700 text-sm">
                    <li>Grounding responses in specific knowledge</li>
                    <li>Reducing "hallucinations"</li>
                    <li>Retrieval from vector databases</li>
                    <li>Query-document relevance</li>
                    <li>Context window optimization</li>
                  </ul>
                </div>
                <div className="bg-white p-3 rounded shadow">
                  <h4 className="font-medium text-blue-800 mb-2">Deployment & MLOps</h4>
                  <ul className="list-disc pl-5 space-y-1 text-gray-700 text-sm">
                    <li>Cloud deployment strategies</li>
                    <li>Containerization (Docker, Kubernetes)</li>
                    <li>Performance monitoring</li>
                    <li>Bias mitigation</li>
                    <li>Explainability approaches</li>
                  </ul>
                </div>
              </div>
            </div>
            
            <div className="bg-green-50 p-5 rounded-lg border border-green-200 mb-6">
              <h3 className="font-semibold text-lg text-green-900 mb-3">Cloud Platforms (Emphasis on Azure)</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="bg-white p-3 rounded shadow">
                  <h4 className="font-medium text-green-800 mb-2">Azure AI Foundry</h4>
                  <ul className="list-disc pl-5 space-y-1 text-gray-700 text-sm">
                    <li>End-to-end platform for GenAI applications</li>
                    <li>Access to foundation models (Azure OpenAI)</li>
                    <li>Model catalogs (Meta, Hugging Face)</li>
                    <li>Prompt engineering and evaluation tools</li>
                    <li>Fine-tuning and RAG capabilities</li>
                  </ul>
                </div>
                <div className="bg-white p-3 rounded shadow">
                  <h4 className="font-medium text-green-800 mb-2">Relevant Azure Services</h4>
                  <ul className="list-disc pl-5 space-y-1 text-gray-700 text-sm">
                    <li>Azure Blob Storage</li>
                    <li>Azure Databricks</li>
                    <li>Azure Kubernetes Service (AKS)</li>
                    <li>Azure AI Search</li>
                    <li>Azure Machine Learning</li>
                  </ul>
                </div>
                <div className="bg-white p-3 rounded shadow">
                  <h4 className="font-medium text-green-800 mb-2">Deployment Options</h4>
                  <ul className="list-disc pl-5 space-y-1 text-gray-700 text-sm">
                    <li>Azure OpenAI service</li>
                    <li>Serverless APIs (Models-as-a-Service)</li>
                    <li>Managed compute infrastructure</li>
                    <li>Cost structure understanding</li>
                    <li>Trade-offs between options</li>
                  </ul>
                </div>
                <div className="bg-white p-3 rounded shadow">
                  <h4 className="font-medium text-green-800 mb-2">AWS/GCP Familiarity</h4>
                  <ul className="list-disc pl-5 space-y-1 text-gray-700 text-sm">
                    <li>AWS SageMaker (vs Azure ML)</li>
                    <li>EC2 for compute</li>
                    <li>S3 for storage</li>
                    <li>GCP Vertex AI concepts</li>
                    <li>Cross-platform knowledge</li>
                  </ul>
                </div>
              </div>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="bg-purple-50 p-4 rounded-lg border border-purple-200">
                <h3 className="font-semibold text-lg text-purple-900 mb-2">Operations Research Fundamentals</h3>
                <div className="bg-white p-3 rounded shadow mb-3">
                  <h4 className="font-medium text-purple-800 mb-2">Core Concepts</h4>
                  <ul className="list-disc pl-5 space-y-1 text-gray-700 text-sm">
                    <li>Optimization goals (cost minimization, efficiency maximization)</li>
                    <li>Linear programming</li>
                    <li>Simulation for complex systems</li>
                    <li>Queueing theory for wait times</li>
                    <li>Scheduling and resource allocation</li>
                  </ul>
                </div>
                <div className="bg-white p-3 rounded shadow">
                  <h4 className="font-medium text-purple-800 mb-2">OR/AI Synergy</h4>
                  <ul className="list-disc pl-5 space-y-1 text-gray-700 text-sm">
                    <li>GenAI assisting in OR problem formulation</li>
                    <li>ML forecasts as inputs to OR models</li>
                    <li>OR optimizing AI deployment strategies</li>
                    <li>Integrated predictive-prescriptive approaches</li>
                  </ul>
                </div>
              </div>
              
              <div className="bg-orange-50 p-4 rounded-lg border border-orange-200">
                <h3 className="font-semibold text-lg text-orange-900 mb-2">Vector Databases</h3>
                <div className="bg-white p-3 rounded shadow mb-3">
                  <h4 className="font-medium text-orange-800 mb-2">Role in RAG/LLMs</h4>
                  <ul className="list-disc pl-5 space-y-1 text-gray-700 text-sm">
                    <li>Storing high-dimensional vector embeddings</li>
                    <li>Fast similarity searches</li>
                    <li>Semantic meaning vs keyword matching</li>
                    <li>Grounding LLM responses in external knowledge</li>
                  </ul>
                </div>
                <div className="bg-white p-3 rounded shadow">
                  <h4 className="font-medium text-orange-800 mb-2">Key Database Options</h4>
                  <ul className="list-disc pl-5 space-y-1 text-gray-700 text-sm">
                    <li>Pinecone: fully managed, cloud-native service</li>
                    <li>FAISS: open-source library from Meta, high performance</li>
                    <li>Weaviate: open-source, stores data objects alongside vectors</li>
                    <li>Hybrid search capabilities</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Application Areas Tab */}
        {activeTab === 'applications' && (
          <div className="p-6">
            <h2 className="text-xl font-bold text-blue-900 mb-4">Potential Application Areas in American Airlines IT Operations</h2>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
                <div className="flex items-center mb-3">
                  <div className="w-10 h-10 rounded-full bg-blue-700 flex items-center justify-center text-white font-bold mr-3">1</div>
                  <h3 className="font-semibold text-lg text-blue-900">IT Process Automation & Knowledge Management</h3>
                </div>
                <ul className="list-disc pl-6 space-y-1 text-gray-700">
                  <li>Automating technical documentation generation</li>
                  <li>Summarizing incident reports and system logs</li>
                  <li>Creating internal knowledge base articles</li>
                  <li>Developing IT support chatbots grounded in AA procedures</li>
                  <li>Improving efficiency and consistency in knowledge sharing</li>
                </ul>
              </div>
              
              <div className="bg-green-50 p-4 rounded-lg border border-green-200">
                <div className="flex items-center mb-3">
                  <div className="w-10 h-10 rounded-full bg-green-700 flex items-center justify-center text-white font-bold mr-3">2</div>
                  <h3 className="font-semibold text-lg text-green-900">Predictive Maintenance for IT Assets</h3>
                </div>
                <ul className="list-disc pl-6 space-y-1 text-gray-700">
                  <li>Analyzing monitoring data from critical IT infrastructure</li>
                  <li>Predicting potential failures or performance degradation</li>
                  <li>Minimizing costly downtime of core airline systems</li>
                  <li>Aligning with Dr. Khemani's PHM expertise</li>
                  <li>Protecting reservations, flight planning, baggage handling systems</li>
                </ul>
              </div>
              
              <div className="bg-purple-50 p-4 rounded-lg border border-purple-200">
                <div className="flex items-center mb-3">
                  <div className="w-10 h-10 rounded-full bg-purple-700 flex items-center justify-center text-white font-bold mr-3">3</div>
                  <h3 className="font-semibold text-lg text-purple-900">IT Resource Optimization</h3>
                </div>
                <ul className="list-disc pl-6 space-y-1 text-gray-700">
                  <li>Combining ML forecasting with OR techniques</li>
                  <li>Optimizing cloud spending on Azure/AWS</li>
                  <li>Dynamic scaling of resources</li>
                  <li>Efficient scheduling of batch processing jobs</li>
                  <li>Managing software license utilization</li>
                  <li>Optimizing network bandwidth allocation</li>
                </ul>
              </div>
              
              <div className="bg-orange-50 p-4 rounded-lg border border-orange-200">
                <div className="flex items-center mb-3">
                  <div className="w-10 h-10 rounded-full bg-orange-700 flex items-center justify-center text-white font-bold mr-3">4</div>
                  <h3 className="font-semibold text-lg text-orange-900">Intelligent IT Support & Service Management</h3>
                </div>
                <ul className="list-disc pl-6 space-y-1 text-gray-700">
                  <li>GenAI-powered tools for IT helpdesk operations</li>
                  <li>Solution suggestion based on problem descriptions</li>
                  <li>Automated ticket categorization and routing</li>
                  <li>Predicting resolution times</li>
                  <li>Identifying recurring issues for proactive management</li>
                </ul>
              </div>
              
              <div className="bg-red-50 p-4 rounded-lg border border-red-200">
                <div className="flex items-center mb-3">
                  <div className="w-10 h-10 rounded-full bg-red-700 flex items-center justify-center text-white font-bold mr-3">5</div>
                  <h3 className="font-semibold text-lg text-red-900">Cybersecurity Enhancement</h3>
                </div>
                <ul className="list-disc pl-6 space-y-1 text-gray-700">
                  <li>Leveraging ML/AI for improved threat detection</li>
                  <li>Analyzing security logs for anomalous patterns</li>
                  <li>Using NLP to understand threat intelligence reports</li>
                  <li>Summarizing security incidents</li>
                  <li>Assisting in security policy analysis</li>
                  <li>Aligns with Dr. Khemani's cybersecurity interest</li>
                </ul>
              </div>
              
              <div className="bg-indigo-50 p-4 rounded-lg border border-indigo-200">
                <div className="flex items-center mb-3">
                  <div className="w-10 h-10 rounded-full bg-indigo-700 flex items-center justify-center text-white font-bold mr-3">6</div>
                  <h3 className="font-semibold text-lg text-indigo-900">Improving IT Project Delivery</h3>
                </div>
                <ul className="list-disc pl-6 space-y-1 text-gray-700">
                  <li>Using GenAI throughout IT project lifecycle</li>
                  <li>Refining requirements documentation</li>
                  <li>Summarizing complex project status reports</li>
                  <li>Analyzing project plans for risks/dependencies</li>
                  <li>Assisting developers with code generation</li>
                </ul>
              </div>
            </div>
            
            <div className="mt-6 bg-gray-100 p-4 rounded-lg">
              <h3 className="font-semibold text-lg mb-2">Strategic Focus</h3>
              <p className="text-gray-700">Focus discussions on <span className="font-medium">internal IT applications</span>. While broader airline examples like optimizing flight routes or crew scheduling demonstrate industry understanding, the interviewer will likely be most interested in how your skills can address challenges within the IT department itself.</p>
            </div>
          </div>
        )}

        {/* Interview Strategy Tab */}
        {activeTab === 'strategy' && (
          <div className="p-6">
            <h2 className="text-xl font-bold text-blue-900 mb-4">Interview Preparation Strategy</h2>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
              <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
                <h3 className="font-semibold text-lg text-blue-900 mb-3">Anticipated Technical Questions</h3>
                <div className="bg-white p-3 rounded shadow mb-3">
                  <h4 className="font-medium text-blue-800 mb-2">Core Concepts Verification</h4>
                  <ul className="list-disc pl-5 space-y-2 text-gray-700 text-sm">
                    <li>"Can you explain Retrieval-Augmented Generation and why it's beneficial for enterprise applications?"</li>
                    <li>"What are the key components or capabilities offered by Azure AI Foundry?"</li>
                    <li>"Walk me through a recent LLM-based project you worked on, focusing on model selection and deployment."</li>
                    <li>"From an OR perspective, how might you approach optimizing IT support staff allocation?"</li>
                    <li>"What is the purpose of a vector database in an LLM application?"</li>
                  </ul>
                </div>
                <div className="bg-white p-3 rounded shadow">
                  <h4 className="font-medium text-blue-800 mb-2">Scenario-Based Problem Solving</h4>
                  <ul className="list-disc pl-5 space-y-2 text-gray-700 text-sm">
                    <li>"How would you leverage GenAI to improve IT asset inventory management?"</li>
                    <li>"Outline steps to build a RAG system using our internal IT policy documents."</li>
                    <li>"If deploying an open-source LLM for summarization on Azure, what options would you consider?"</li>
                  </ul>
                </div>
              </div>
              
              <div className="bg-green-50 p-4 rounded-lg border border-green-200">
                <h3 className="font-semibold text-lg text-green-900 mb-3">Highlighting Relevant Experience</h3>
                <div className="bg-white p-3 rounded shadow mb-3">
                  <h4 className="font-medium text-green-800 mb-2">Align with Job Description</h4>
                  <ul className="list-disc pl-5 space-y-1 text-gray-700 text-sm">
                    <li>Python programming experience</li>
                    <li>Hands-on LLM development (GPT, Llama, etc.)</li>
                    <li>RAG implementation details</li>
                    <li>Vector Database usage (Pinecone, FAISS, Weaviate)</li>
                    <li>Cloud platform experience (Azure AI Foundry)</li>
                    <li>MLOps tools and practices</li>
                  </ul>
                </div>
                <div className="bg-white p-3 rounded shadow mb-3">
                  <h4 className="font-medium text-green-800 mb-2">Quantify Impact</h4>
                  <ul className="list-disc pl-5 space-y-1 text-gray-700 text-sm">
                    <li>Cost reduction percentages</li>
                    <li>Efficiency improvements</li>
                    <li>Accuracy metrics</li>
                    <li>Time savings</li>
                    <li>Business value created</li>
                  </ul>
                </div>
                <div className="bg-white p-3 rounded shadow">
                  <h4 className="font-medium text-green-800 mb-2">Connect to IT/OR Context</h4>
                  <ul className="list-disc pl-5 space-y-1 text-gray-700 text-sm">
                    <li>Process optimization examples</li>
                    <li>System reliability improvements</li>
                    <li>Resource efficiency achievements</li>
                    <li>Operational analytics applications</li>
                    <li>System-level problem solving</li>
                  </ul>
                </div>
              </div>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
              <div className="bg-purple-50 p-4 rounded-lg border border-purple-200">
                <h3 className="font-semibold text-lg text-purple-900 mb-3">Demonstrating Soft Skills</h3>
                <div className="grid grid-cols-2 gap-3">
                  <div className="bg-white p-3 rounded shadow">
                    <h4 className="font-medium text-purple-800 mb-2">Communication</h4>
                    <ul className="list-disc pl-5 space-y-1 text-gray-700 text-sm">
                      <li>Clear, concise technical explanations</li>
                      <li>Logical structure in responses</li>
                      <li>Active listening</li>
                      <li>Adapting to audience</li>
                    </ul>
                  </div>
                  <div className="bg-white p-3 rounded shadow">
                    <h4 className="font-medium text-purple-800 mb-2">Problem-Solving</h4>
                    <ul className="list-disc pl-5 space-y-1 text-gray-700 text-sm">
                      <li>Structured approach</li>
                      <li>Verbalize thought process</li>
                      <li>Consider trade-offs</li>
                      <li>Justify decisions</li>
                    </ul>
                  </div>
                  <div className="bg-white p-3 rounded shadow">
                    <h4 className="font-medium text-purple-800 mb-2">Learning Agility</h4>
                    <ul className="list-disc pl-5 space-y-1 text-gray-700 text-sm">
                      <li>Enthusiasm for new tech</li>
                      <li>Adaptability examples</li>
                      <li>Continuous learning mindset</li>
                      <li>Skill development approach</li>
                    </ul>
                  </div>
                  <div className="bg-white p-3 rounded shadow">
                    <h4 className="font-medium text-purple-800 mb-2">Collaboration</h4>
                    <ul className="list-disc pl-5 space-y-1 text-gray-700 text-sm">
                      <li>Cross-functional team experience</li>
                      <li>Stakeholder management</li>
                      <li>Technical-business translation</li>
                      <li>Conflict resolution approach</li>
                    </ul>
                  </div>
                </div>
              </div>
              
              <div className="bg-orange-50 p-4 rounded-lg border border-orange-200">
                <h3 className="font-semibold text-lg text-orange-900 mb-3">Questions to Ask the Interviewer</h3>
                <div className="bg-white p-3 rounded shadow mb-3">
                  <ul className="list-disc pl-5 space-y-2 text-gray-700 text-sm">
                    <li>"Could you elaborate on the types of IT operations problems the Gen AI team is currently focusing on?"</li>
                    <li>"What does the typical project lifecycle look like for a GenAI initiative within the OR&AA team?"</li>
                    <li>"How extensively is Azure AI Foundry currently used by the team, and what capabilities do you find most valuable?"</li>
                    <li>"How does the team approach ensuring the long-term reliability and maintainability of AI/ML models in production?"</li>
                    <li>"What opportunities exist to collaborate with colleagues who have deep expertise in traditional Operations Research methods?"</li>
                    <li>"What are the biggest challenges or opportunities you see for applying GenAI within American Airlines' IT Operations?"</li>
                  </ul>
                </div>
              </div>
            </div>
            
            <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
              <h3 className="font-semibold text-lg text-blue-900 mb-3">Key Success Factors</h3>
              <ol className="list-decimal pl-6 space-y-2 text-gray-700">
                <li><span className="font-medium">Demonstrate practical LLM/GenAI experience:</span> Emphasize hands-on involvement with the complete development lifecycle, particularly RAG implementation and prompt engineering.</li>
                <li><span className="font-medium">Show Azure ecosystem familiarity:</span> Highlight specific knowledge of Azure AI Foundry and its components, differentiating from generic cloud experience.</li>
                <li><span className="font-medium">Connect technical skills to IT operations:</span> Frame examples and potential solutions in the context of internal IT challenges rather than general airline operations.</li>
                <li><span className="font-medium">Emphasize reliability and robustness:</span> Align with Dr. Khemani's background by discussing how solutions can be made dependable, maintainable, and operationally viable.</li>
                <li><span className="font-medium">Quantify impact:</span> Whenever possible, express outcomes in measurable terms to demonstrate business value orientation.</li>
              </ol>
            </div>
          </div>
        )}
      </div>
      
      <footer className="text-center text-gray-500 text-sm mt-6">
        <p>Analysis Dashboard for American Airlines Data Scientist Interview Preparation (Req 78278)</p>
      </footer>
    </div>
  );
};

export default Dashboard;
