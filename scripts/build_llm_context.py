import os

# Base paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KB_DIR = os.path.join(BASE_DIR, 'docs', 'kb')
WIKI_PATH = os.path.join(BASE_DIR, 'docs', 'wiki.html')
LLM_CONTEXT_PATH = os.path.join(BASE_DIR, 'docs', 'OUTCALL_MASTER_LLM_CONTEXT.md')

def gather_markdown_files():
    markdown_files = []
    # Gather root KB files
    for f in os.listdir(KB_DIR):
        if f.endswith('.md'):
            markdown_files.append(os.path.join(KB_DIR, f))
    
    # Gather calls KB files
    calls_dir = os.path.join(KB_DIR, 'calls')
    if os.path.exists(calls_dir):
        for f in os.listdir(calls_dir):
            if f.endswith('.md'):
                markdown_files.append(os.path.join(calls_dir, f))
    
    return sorted(markdown_files)

def generate_llm_context():
    files = gather_markdown_files()
    
    print(f"Compiling {len(files)} files into {LLM_CONTEXT_PATH}...")
    
    master_content = []
    master_content.append("# OUTCALL - THE MASTER KNOWLEDGE BASE")
    master_content.append("This document contains the entire 44-article encyclopedia, wiki, and technical documentation for the OUTCALL application. It is specifically compiled for LLM ingestion. Use this to reference bioacoustics, hunting strategies, app architecture, AI scoring, and premium mechanics.")
    master_content.append("\\n---\\n")
    
    for relative_path in files:
        file_name = os.path.basename(relative_path)
        category = "Calls" if "calls" in relative_path else "Technical/Core"
        
        with open(relative_path, 'r', encoding='utf-8') as f:
            content = f.read().strip()
            
        master_content.append(f"## FILE: `{file_name}` [Category: {category}]")
        master_content.append("<document_content>")
        master_content.append(content)
        master_content.append("</document_content>")
        master_content.append("\\n---\\n")

    with open(LLM_CONTEXT_PATH, 'w', encoding='utf-8') as f:
        f.write('\\n'.join(master_content))
        
    print("SUCCESS: Master LLM Context file generated.")

if __name__ == '__main__':
    generate_llm_context()
