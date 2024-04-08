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
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-11-20"
	}

	input {
		String path_exe = "bwa"

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
		~{path_exe} 2>&1 | grep "Program\|Version\|Contact"
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
			description: 'Path used as executable [default: "bwa"]',
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

# Options optimizations :
#	- It seems that option "-V" didn't do anything
#	- Since minimap2 replace BWA for long-reads it seems deprecated to use "-x"
#	- It seems unnecessary to change all options in the human context

task memnosort {
	meta {
		author: "Olivier Ardouin"
		email: "o-ardouin(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2021-11-23"
	}

	input {
		String path_exe = "bwa"

		String? outputPath
		String? sample
		String subString = "(_S[0-9]+)?(_L[0-9][0-9][0-9])?(_R[12])?(_[0-9][0-9][0-9])?.(fastq|fq)(.gz)?"
		String subStringReplace = ""

		File fastqR1
		File? fastqR2

		File refFasta
		File refFai
		File refAmb
		File refAnn
		File refBwt
		File refPac
		File refSa

		String platformReads = "ILLUMINA"

		Boolean markShorter = true
		Int minScore = 30

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
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}.sam" else "~{baseName}.sam"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} mem \
			-R "@RG\tID:~{baseName}\tSM:~{baseName}\tPL:~{platformReads}" \
			-T ~{minScore} \
			~{true="-M" false="" markShorter} \
			-t ~{threads} \
			~{refFasta} \
			~{fastqR1} ~{default="" fastqR2} \
	>>>

	output {
		File outputFile = stdout()
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "bwa"]',
			category: 'System'
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
			category: 'Required'
		}
		fastqR2: {
			description: 'Input file with reads 2 (fastq, fastq.gz, fq, fq.gz).',
			category: 'Tool option'
		}
		refFasta: {
			description: 'Path to the reference file (format: fasta)',
			category: 'Required'
		}
		platformReads: {
			description: 'Type of plateform that produce reads [default: ILLUMINA]',
			category: 'Tool option'
		}
		markShorter: {
			description: 'Mark shorter split hits as secondary (for Picard compatibility). [default: true]',
			category: 'Tool option'
		}
		minScore: {
			description: 'Don’t output alignment with score lower than this value. [default: 30]',
			category: 'Tool option'
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

task mem {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.2"
		date: "2021-03-05"
	}

	input {
		String path_exe = "bwa"
		String path_exe_samtools = "samtools"

		String? outputPath
		String? sample
		String subString = "(_S[0-9]+)?(_L[0-9][0-9][0-9])?(_R[12])?(_[0-9][0-9][0-9])?.(fastq|fq)(.gz)?"
		String subStringReplace = ""

		File fastqR1
		File? fastqR2

		File refFasta
		File refFai
		File refAmb
		File refAnn
		File refBwt
		File refPac
		File refSa

		String platformReads = "ILLUMINA"

		Boolean markShorter = true
		Int minScore = 30

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
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}.bam" else "~{baseName}.bam"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} mem \
			-R "@RG\tID:~{baseName}\tSM:~{baseName}\tPL:~{platformReads}" \
			-T ~{minScore} \
			~{true="-M" false="" markShorter} \
			-t ~{threads} \
			~{refFasta} \
			~{fastqR1} ~{default="" fastqR2} \
			| ~{path_exe_samtools} sort -@ ~{threads-1} -m ~{memoryByThreadsMb}M -o ~{outputFile}

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
			description: 'Path used as executable [default: "bwa"]',
			category: 'System'
		}
		path_exe_samtools: {
			description: 'Path used as executable [default: "samtools"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where bam file was generated. [default: pwd()]',
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
			category: 'Required'
		}
		fastqR2: {
			description: 'Input file with reads 2 (fastq, fastq.gz, fq, fq.gz).',
			category: 'Tool option'
		}
		refFasta: {
			description: 'Path to the reference file (format: fasta)',
			category: 'Required'
		}
		platformReads: {
			description: 'Type of plateform that produce reads [default: ILLUMINA]',
			category: 'Tool option'
		}
		markShorter: {
			description: 'Mark shorter split hits as secondary (for Picard compatibility). [default: true]',
			category: 'Tool option'
		}
		minScore: {
			description: 'Don’t output alignment with score lower than this value. [default: 30]',
			category: 'Tool option'
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

task index {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-07-30"
	}

	input {
		String path_exe = "bwa"

		File in
		String? outputPath

		String? algo
		String? name
		Int? blockSize
		Boolean sixtyFour = false

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else basename(in)
	String outputBaseName = if defined(outputPath) then "~{outputPath}/~{baseName}" else "~{baseName}"

	command <<<

		if [[ ! -d $(dirname ~{outputBaseName}) ]]; then
			mkdir -p $(dirname ~{outputBaseName})
		fi

		~{path_exe} index \
			~{default="" "-a " + algo} \
			~{default="" "-b " + blockSize} \
			~{true="-6" false="" sixtyFour} \
			-p ~{outputBaseName} \
			~{in}

	>>>

	output {
		File refAmb = outputBaseName + ".amb"
		File refAnn = outputBaseName + ".ann"
		File refPac = outputBaseName + ".pac"
		File refBwt = outputBaseName + ".bwt"
		File refSa = outputBaseName + ".sa"
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "bwa"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where bam file was generated. [default: pwd()]',
			category: 'Output path/name option'
		}
		in:	{
			description: 'Fasta file to index by bwa.',
			category: 'Required'
		}
		algo: {
			description: 'BWT construction algorithm: bwtsw, is or rb2 [auto]',
			category: 'Tool option'
		}
		name: {
			description: 'Prefix of the index files names [fasta name]',
			category: 'Tool option'
		}
		blockSize: {
			description: 'Block size for the bwtsw algorithm (effective with algo: bwtsw)',
			category: 'Tool option'
		}
		sixtyFour: {
			description: 'Index files named as <in.fasta>.64.* instead of <in.fasta>.*',
			category: 'Tool option'
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
