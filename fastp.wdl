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
		author: "Oliver Ardouin"
		email: "o-ardouin(at)chu-montpellier.fr"
		version: "0.0.2"
		date: "2022-03-16"
	}

	input {
		String path_exe = "fastp"

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
		String version = read_string(stderr())
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "fastp"]',
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

task fastp_pe {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-07-29"
	}

	input {
		String path_exe = "fastp"

		String? outputPath
		String? sample
		String subString = "(_S[0-9]+)?(_L[0-9][0-9][0-9])?(_R[12])?(_[0-9][0-9][0-9])?.(fastq|fq)(.gz)?"
		String subStringReplace = ""

		File fastqR1
		File fastqR2

		Boolean unpaired1 = false
		Boolean unpaired2 = false

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(sample) then sample else sub(basename(fastqR1),subString,subStringReplace)
	String outputBase = if defined(outputPath) then "~{outputPath}/~{baseName}" else "~{baseName}"

	command <<<

		if [[ ! -d ~{outputPath} ]]; then
			mkdir -p ~{outputPath}
		fi

		~{path_exe} \
			--in1 ~{fastqR1} \
			--in2 ~{fastqR2} \
			~{true="--unpaired1" false="" unpaired1} \
			~{true="--unpaired2" false="" unpaired2} \
			--out1 ~{outputBase}.R1.fq.gz \
			--out2 ~{outputBase}.R2.fq.gz \
			--report_title ~{baseName} \
			--json ~{outputBase}.json \
			--html ~{outputBase}.html \
			--thread ~{threads}

	>>>

	output {
		File FastpR1 = "~{outputBase}.R1.fq.gz"
		File FastpR2 = "~{outputBase}.R2.fq.gz"
		File fastpJson = "~{outputBase}.json"
		File fastpHtml = "~{outputBase}.html"
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "fastqc"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where files will be generated. [default: pwd()]',
			category: 'Output path/name option'
		}
		sample: {
			description: 'Sample name to use for output file name [default: sub(basename(fastqR1),subString,"")]',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Substring to remove to get sample name [default: "(_S[0-9]+)?(_L[0-9][0-9][0-9])?(_R[12])?(_[0-9][0-9][0-9])?.(fastq|fq)(.gz)?"]',
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
		unpaired1: {
			description: 'If read1 passed QC but read2 not, it will be written to unpaired1. [default: false]',
			category: 'Tool options'
		}
		unpaired2: {
			description: 'If read1 passed QC but read2 not, it will be written to unpaired1. [default: false]',
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
	}
}
