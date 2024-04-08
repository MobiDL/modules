version 1.0

# MobiDL 2.0 - MobiDL 2 is a collection of tools wrapped in WDL to be used in any WDL pipelines.
# Copyright (C) 2021 MoBiDiC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

task get_version {
	meta {
    author: "Olivier Ardouin"
    email: "o-ardouin(at)chu-montpellier.fr"
    version: "0.0.1"
    date: "2021-10-28"
  }

	input {
		String path_exe = "multiqc"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	command <<<
		~{path_exe} --version
	>>>

	output {
		String version = read_string(stdout())
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "mpa"]',
			category: 'System'
		}
		threads: {
			description: 'Sets the number of threads [default: 1]',
			category: 'System'
		}
		memory: {
			description: 'Sets the total memory to use ; with suffix M/G [default: (memoryByThreads*threads)M]',
			category: 'System'
		}
		memoryByThreads: {
			description: 'Sets the total memory to use (in M) [default: 768]',
			category: 'System'
		}
	}
}

task multiqc {
	meta {
    author: "Olivier Ardouin"
    email: "o-ardouin(at)chu-montpellier.fr"
    version: "0.0.1"
    date: "2021-10-28"
  }

	input {
		String path_exe = "multiqc"
		String path_to_check

		String outputPath = "./"
		String? name
		String? comment
		Array[File]? MetrixFiles
		Array[Array[File]]? MetrixParentFiles

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)


	String outdir = "--outdir ~{outputPath} "
	String title = if defined(name) then "--title ~{name} " else ""
	String comm = if defined(comment) then "--comment \"~{comment}\" " else ""
	String FileName = if defined(name) then "--filename ~{name}_multiqc_report " else "--filename multiqc_report"

	String outputFile = if defined(name) then "~{outputPath}/~{name}_multiqc_report.html" else "~{outputPath}/multiqc_report.html"

	command <<<
		set exo pipefail

		if [[ ! -d ~{outputPath} ]]; then
			mkdir -p ~{outputPath}
		fi

		~{path_exe} ~{path_to_check} ~{FileName} ~{title} ~{comm} ~{outdir} -q
	>>>

	output {
		File outputFile = outputFile
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "multiqc"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where files were generated. [default: pwd()]',
			category: 'Output path/name option'
		}
		name: {
			description: 'Name to use for output name in file and repport',
			category: 'Output path/name option'
		}
		comment: {
			description: 'Name to use for output name in file and repport',
			category: 'Output path/name option'
		}
		path_to_check: {
			description: 'Input Path for detect QC files',
			category: 'Required'
		}
		threads: {
			description: 'Sets the number of threads [default: 1]',
			category: 'System'
		}
		memory: {
			description: 'Sets the total memory to use ; with suffix M/G [default: (memoryByThreads*threads)M]',
			category: 'System'
		}
		memoryByThreads: {
			description: 'Sets the total memory to use (in M) [default: 768]',
			category: 'System'
		}
	}
}
