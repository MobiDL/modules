version 1.0

# MobiDL 2.0 - MobiDL 2 is a collection of tools wrapped in WDL to be used in any WDL pipelines.
# Copyright (C) 2026 MoBiDiC
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
		author: "Charles Van Goethem"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.1.0"
		date: "2026-07-15"
	}

	input {
		String path_exe = "minibwa"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
		String apptainer_img = "minibwa:0.3"
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	command <<<
		~{path_exe} version
	>>>

	output {
		String version = "minibwa ~{stdout()}"
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
		docker: "~{apptainer_img}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "minibwa"]',
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
		apptainer_img: {
			description: 'Sets the apptainer image you want to use [default: minibwa:0.3]',
			category: 'System'
		}
	}
}

task map {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.1.1"
		date: "2026-08-22"
	}

	input {
		String path_exe = "minibwa"

		String outputPath
		String subdir = ""
		String? sample
		String subString = ".(fastq|fq)(.gz)?"
		String subStringReplace = ""

		String platform="AVITI"

		File fastqR1
		File fastqR2

		File fasta
		File fasta_l2b = fasta + ".l2b"
		File fasta_mbw = fasta + ".mbw"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
		String apptainer_img = "minibwa:0.3"
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(sample) then sample else sub(basename(fastqR1),subString,subStringReplace)
	String outputBase = "~{outputPath}/~{subdir}/~{baseName}"

	command <<<

		if [[ ! -d $(dirname ~{outputBase}) ]]; then
			mkdir -p $(dirname ~{outputBase})
		fi

		~{path_exe} map \
			-t ~{threads} \
			-R "@RG\tID:~{baseName}\tSM:~{baseName}\tPL:~{platform}" \
			"~{fasta}" \
			"~{fastqR1}" \
			"~{fastqR2}" \
			-o "~{outputBase}.sam"

	>>>

	output {
		File sam = "~{outputBase}.sam"
	}

	runtime {
		bind_opt: "~{outputPath}/~{subdir}" + "," + "~{fasta}" + "," + "~{fastqR1}" + "," + "~{fastqR2}"
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
		docker: "~{apptainer_img}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "minibwa"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where files will be generated. [default: pwd()]',
			category: 'Output path/name option'
		}
        subdir: {
			description: 'Subdirectory where to write output. [default: ""]',
			category: 'Output path/name option'
        }
		sample: {
			description: 'Sample name to use for output file name [default: sub(basename(fastqR1),subString,"")]',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Substring to remove to get sample name [default: ".(fastq|fq)(.gz)?"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'subString replace by this string [default: ""]',
			category: 'Output path/name option'
		}
		fastqR1: {
			description: 'Input file with reads 1 (fastq, fastq.gz, fq, fq.gz).',
			category: 'Input'
		}
		fastqR2: {
			description: 'Input file with reads 2 (fastq, fastq.gz, fq, fq.gz).',
			category: 'Input'
		}
		platform: {
			description: 'Type of platform that produce reads [default: "AVITI"]',
			category: 'Tool options'
		}
		fasta: {
			description: 'Path to the reference file (format: fasta)',
			category: 'Tool options'
		}
		fasta_l2b: {
			description: 'Path to the reference file l2b index [default: fasta.l2b]',
			category: 'Tool options'
		}
		fasta_mbw: {
			description: 'Path to the reference file mbw index [default: fasta.mbw]',
			category: 'Tool options'
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
		apptainer_img: {
			description: 'Sets the apptainer image you want to use [default: minibwa:0.3]',
			category: 'System'
		}
	}
}
