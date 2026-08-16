import json
from pathlib import Path
from typing import Any, Dict, Optional
from utils.logger import get_logger

logger = get_logger("file_utils")


def validate_file_path(filepath: str) -> Optional[Path]:
    """Validates if file exists and is readable."""
    if not filepath or not filepath.strip():
        return None
    path = Path(filepath.strip().strip('"').strip("'"))
    if path.exists() and path.is_file():
        return path
    logger.warning(f"File not found or invalid: {filepath}")
    return None


def extract_text_from_pdf(pdf_path: Path) -> str:
    """Extracts text content from a PDF file using pypdf."""
    try:
        import pypdf
        reader = pypdf.PdfReader(str(pdf_path))
        text = ""
        for page in reader.pages:
            extracted = page.extract_text()
            if extracted:
                text += extracted + "\n"
        return text.strip()
    except Exception as e:
        logger.error(f"Error reading PDF file {pdf_path}: {e}")
        return ""


def extract_text_from_docx(docx_path: Path) -> str:
    """Extracts text content from a DOCX file using python-docx."""
    try:
        import docx
        doc = docx.Document(str(docx_path))
        text = "\n".join([para.text for para in doc.paragraphs if para.text])
        return text.strip()
    except Exception as e:
        logger.error(f"Error reading DOCX file {docx_path}: {e}")
        return ""


def parse_resume_file(filepath: str) -> str:
    """Extracts text from a PDF or DOCX resume file."""
    path = validate_file_path(filepath)
    if not path:
        return ""

    suffix = path.suffix.lower()
    if suffix == ".pdf":
        return extract_text_from_pdf(path)
    elif suffix in [".docx", ".doc"]:
        return extract_text_from_docx(path)
    elif suffix == ".txt":
        try:
            return path.read_text(encoding="utf-8")
        except Exception as e:
            logger.error(f"Error reading TXT file {path}: {e}")
            return ""
    else:
        logger.warning(f"Unsupported file format: {suffix}")
        return ""


def save_report_files(report_data: Dict[str, Any], text_report: str, candidate_name: str, reports_dir: Path) -> tuple[Path, Path]:
    """Saves completed report in both JSON and TXT format locally."""
    reports_dir.mkdir(parents=True, exist_ok=True)
    clean_name = "".join(c if c.isalnum() else "_" for c in candidate_name.lower())
    from datetime import datetime
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    json_filename = f"interview_{clean_name}_{timestamp}.json"
    txt_filename = f"interview_{clean_name}_{timestamp}.txt"

    json_path = reports_dir / json_filename
    txt_path = reports_dir / txt_filename

    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(report_data, f, indent=2, ensure_ascii=False)

    with open(txt_path, "w", encoding="utf-8") as f:
        f.write(text_report)

    logger.info(f"Report saved successfully to:\n- {json_path}\n- {txt_path}")
    return json_path, txt_path
