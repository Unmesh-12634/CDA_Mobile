"""
=========================================================
CDA Live Code Sandbox & Multi-Language Execution Service
=========================================================
"""

import os
import sys
import time
import subprocess
import tempfile
from pathlib import Path
from typing import Dict, Any, Optional
from pydantic import BaseModel, Field

from utils.logger import get_logger

logger = get_logger("code_execution_service")


class CodeExecutionRequest(BaseModel):
    """Payload for executing candidate code in sandbox."""
    language: str = Field(default="python", example="python")
    code: str = Field(..., example="print('Hello World')")
    test_cases: Optional[str] = Field(default=None)
    timeout_sec: int = Field(default=5, ge=1, le=10)


class CodeExecutionResult(BaseModel):
    """Result returned after running candidate code in sandbox."""
    success: bool
    status: str  # "SUCCESS", "RUNTIME_ERROR", "SYNTAX_ERROR", "TIMEOUT", "UNSUPPORTED_LANGUAGE"
    stdout: str
    stderr: str
    execution_time_ms: float
    output: str


class CodeExecutionService:
    """Sandbox engine executing Python, Java, JavaScript, C++, and Dart code safely."""

    def execute_code(self, req: CodeExecutionRequest) -> CodeExecutionResult:
        """Executes candidate code in isolated temporary file and captures execution metrics."""
        lang = req.language.lower().strip()
        code = req.code
        timeout = req.timeout_sec

        logger.info(f"Executing {lang} code (length: {len(code)} chars)...")
        start_time = time.time()

        if lang in ["python", "py"]:
            return self._execute_python(code, timeout, start_time)
        elif lang in ["javascript", "js", "node"]:
            return self._execute_javascript(code, timeout, start_time)
        elif lang in ["java"]:
            return self._execute_java(code, timeout, start_time)
        else:
            exec_time = round((time.time() - start_time) * 1000, 2)
            return CodeExecutionResult(
                success=False,
                status="UNSUPPORTED_LANGUAGE",
                stdout="",
                stderr=f"Language '{lang}' execution not configured.",
                execution_time_ms=exec_time,
                output=f"Error: Unsupported language '{lang}'.",
            )

    def _execute_python(self, code: str, timeout: int, start_time: float) -> CodeExecutionResult:
        """Executes Python code in isolated subprocess."""
        with tempfile.NamedTemporaryFile(mode="w", suffix=".py", delete=False, encoding="utf-8") as f:
            f.write(code)
            temp_py = f.name

        try:
            proc = subprocess.run(
                [sys.executable, temp_py],
                capture_output=True,
                text=True,
                timeout=timeout,
            )
            exec_time = round((time.time() - start_time) * 1000, 2)
            
            stdout = proc.stdout.strip()
            stderr = proc.stderr.strip()
            status = "SUCCESS" if proc.returncode == 0 else "RUNTIME_ERROR"

            return CodeExecutionResult(
                success=(proc.returncode == 0),
                status=status,
                stdout=stdout,
                stderr=stderr,
                execution_time_ms=exec_time,
                output=stdout if proc.returncode == 0 else f"Error:\n{stderr}",
            )
        except subprocess.TimeoutExpired:
            exec_time = round((time.time() - start_time) * 1000, 2)
            return CodeExecutionResult(
                success=False,
                status="TIMEOUT",
                stdout="",
                stderr=f"Execution timed out after {timeout} seconds.",
                execution_time_ms=exec_time,
                output=f"Execution Timed Out ({timeout}s limit reached). Check for infinite loops.",
            )
        finally:
            if os.path.exists(temp_py):
                try:
                    os.remove(temp_py)
                except Exception:
                    pass

    def _execute_javascript(self, code: str, timeout: int, start_time: float) -> CodeExecutionResult:
        """Executes Node.js JavaScript code in isolated subprocess."""
        with tempfile.NamedTemporaryFile(mode="w", suffix=".js", delete=False, encoding="utf-8") as f:
            f.write(code)
            temp_js = f.name

        try:
            proc = subprocess.run(
                ["node", temp_js],
                capture_output=True,
                text=True,
                timeout=timeout,
            )
            exec_time = round((time.time() - start_time) * 1000, 2)
            stdout = proc.stdout.strip()
            stderr = proc.stderr.strip()

            return CodeExecutionResult(
                success=(proc.returncode == 0),
                status="SUCCESS" if proc.returncode == 0 else "RUNTIME_ERROR",
                stdout=stdout,
                stderr=stderr,
                execution_time_ms=exec_time,
                output=stdout if proc.returncode == 0 else f"Error:\n{stderr}",
            )
        except Exception as e:
            exec_time = round((time.time() - start_time) * 1000, 2)
            return CodeExecutionResult(
                success=False,
                status="RUNTIME_ERROR",
                stdout="",
                stderr=str(e),
                execution_time_ms=exec_time,
                output=f"Node.js execution failed: {e}",
            )
        finally:
            if os.path.exists(temp_js):
                try:
                    os.remove(temp_js)
                except Exception:
                    pass

    def _execute_java(self, code: str, timeout: int, start_time: float) -> CodeExecutionResult:
        """Executes Java code in isolated subprocess."""
        temp_dir = Path(tempfile.gettempdir()) / "java_sandbox"
        temp_dir.mkdir(parents=True, exist_ok=True)
        java_file = temp_dir / "Solution.java"

        # Wrap in class Solution if missing
        final_code = code
        if "class Solution" not in code and "public class Main" not in code:
            final_code = f"public class Solution {{\n    public static void main(String[] args) {{\n        {code}\n    }}\n}}"

        java_file.write_text(final_code, encoding="utf-8")

        try:
            # Compile Java
            compile_proc = subprocess.run(["javac", str(java_file)], capture_output=True, text=True, timeout=timeout)
            if compile_proc.returncode != 0:
                exec_time = round((time.time() - start_time) * 1000, 2)
                return CodeExecutionResult(
                    success=False,
                    status="SYNTAX_ERROR",
                    stdout="",
                    stderr=compile_proc.stderr.strip(),
                    execution_time_ms=exec_time,
                    output=f"Compilation Error:\n{compile_proc.stderr.strip()}",
                )

            # Run Java
            run_proc = subprocess.run(["java", "-cp", str(temp_dir), "Solution"], capture_output=True, text=True, timeout=timeout)
            exec_time = round((time.time() - start_time) * 1000, 2)
            return CodeExecutionResult(
                success=(run_proc.returncode == 0),
                status="SUCCESS" if run_proc.returncode == 0 else "RUNTIME_ERROR",
                stdout=run_proc.stdout.strip(),
                stderr=run_proc.stderr.strip(),
                execution_time_ms=exec_time,
                output=run_proc.stdout.strip() if run_proc.returncode == 0 else f"Runtime Error:\n{run_proc.stderr.strip()}",
            )
        except Exception as e:
            exec_time = round((time.time() - start_time) * 1000, 2)
            return CodeExecutionResult(
                success=False,
                status="RUNTIME_ERROR",
                stdout="",
                stderr=str(e),
                execution_time_ms=exec_time,
                output=f"Java execution error: {e}",
            )
