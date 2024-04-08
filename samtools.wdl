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
		String path_exe = "samtools"

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
			description: 'Path used as executable [default: "samtools"]',
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

task sort {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-07-30"
	}

	input {
		String path_exe = "samtools"

		File in
		String? outputPath
		String? name
		String suffix = ".sort"
		String format = "bam"

		Int compressionLevel = 6
		Boolean sortByReadName = false
		String? tag
		File? refFasta

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else sub(basename(in),"(\.sam|\.bam|\.cram)","")
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{suffix}.~{format}" else "~{baseName}~{suffix}.~{format}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} sort \
			-l ~{compressionLevel} \
			~{true="-n" false="" sortByReadName} \
			~{default="" "-t " + tag} \
			--output-fmt ~{format} \
			~{default="" "--reference " + refFasta} \
			--threads ~{threads - 1} \
			-m ~{memoryByThreadsMb}M \
			-o ~{outputFile} \
			~{in}

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
			description: 'Path used as executable [default: "samtools"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where bam file was generated. [default: pwd()]',
			category: 'Tool option'
		}
		name: {
			description: 'Name to use for output file name [default: sub(basename(in),"(\.bam|\.sam|\.cram)","")]',
			category: 'Tool option'
		}
		in: {
			description: 'Bam file to sort.',
			category: 'Required'
		}
		suffix: {
			description: 'Suffix to add on the output file (e.g. sample.suffix.bam) [default: ".sort"]',
			category: 'Tool option'
		}
		format: {
			description: 'Specify a single output file format option [default: "bam"]',
			category: 'Tool option'
		}
		compressionLevel: {
			description: 'Specify compression level of the resulting file (from 0 to 9) [default: 6]',
			category: 'Tool option'
		}
		sortByReadName: {
			description: 'Sort by read name [default: false]',
			category: 'Tool option'
		}
		tag: {
			description: 'Sort by value of TAG. Uses position as secondary index (or read name if -n is set)',
			category: 'Tool option'
		}
		refFasta: {
			description: 'Reference sequence FASTA FILE',
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

task dict {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-07-30"
	}

	input {
		String path_exe = "samtools"

		File in
		String? outputPath
		String? name
		String ext = ".dict"
		String subString = "\.fa(sta)?(\.gz)?"

		String? assembly
		Boolean header = true
		String? species
		String? uri

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else sub(basename(in),subString,"")
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{ext}" else "~{baseName}~{ext}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} dict \
			~{default="" "--assembly " + assembly} \
			~{true="" false="--no-header" header} \
			~{default="" "--species " + species} \
			~{default="" "--uri " + uri} \
			-o ~{outputFile} \
			~{in}

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
			description: 'Path used as executable [default: "samtools"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where dict file was generated. [default: pwd()]',
			category: 'Tool option'
		}
		name: {
			description: 'Name to use for output file name [default: sub(basename(in),subString,"")]',
			category: 'Tool option'
		}
		in: {
			description: 'Fasta file.',
			category: 'Required'
		}
		ext: {
			description: 'Extension of the output file (e.g. mygenome.dict) [default: ".dict"]',
			category: 'Tool option'
		}
		subString: {
			description: 'Substring to remove to get file basename [default: "\.fa(sta)?(\.gz)?"]',
			category: 'Tool option'
		}
		assembly: {
			description: 'Assembly',
			category: 'Tool option'
		}
		header: {
			description: 'Print the header (@HD line) [default: true]',
			category: 'Tool option'
		}
		uri: {
			description: 'URI (e.g. file:///abs/path/to/file.fa)',
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
		date: "2020-07-31"
	}

	input {
		String path_exe = "samtools"

		File in
		String? outputPath
		String? name

		Int? minIntervalSize
		Boolean csi = false

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String extFile = sub(basename(in),"(.*)\.(bam|cram)$","$2")
	Boolean csiOpt = if (defined(minIntervalSize) || csi) then true else false
	String ext = if extFile=="cram" then ".crai" else if csiOpt then ".csi" else ".bai"

	String baseName = if defined(name) then name else basename(in)
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{ext}" else "~{baseName}~{ext}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} index \
			~{true="-c" false="-b" csiOpt} \
			~{default="" "-m " + minIntervalSize} \
			-@ ~{threads} \
			~{in} \
			~{outputFile}

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
			description: 'Path used as executable [default: "samtools"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where index was generated. [default: pwd()]',
			category: 'Tool option'
		}
		name: {
			description: 'Name to use for output file name [default: basename(in)]',
			category: 'Tool option'
		}
		in: {
			description: 'Input bam or cram to index.',
			category: 'Required'
		}
		minIntervalSize: {
			description: 'Set minimum interval size for CSI indices to 2^INT.',
			category: 'Tool option'
		}
		csi: {
			description: 'Generate CSI-format index for BAM files (not functionnal with cram files) [default: false]',
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

task view {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-07-31"
	}

	input {
		String path_exe = "samtools"

		File in
		String? outputPath
		String? name
		Boolean cram = false

		File? refFai
		File? refFasta

		File? bed
		String? readGroup
		File? readGroupFile
		Int minQuality = 0
		String? library
		Int minCigarOp = 0

		Boolean multiRegioOperator = false
		Boolean collapseCigarOp =false

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String ext = if cram then "cram" else "bam"
	String baseName = if defined(name) then name else sub(basename(in),"(\.bam|\.cram|\.sam)","")
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}.~{ext}" else "~{baseName}.~{ext}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} view \
			~{true="-C" false="-b" cram} \
			-o ~{outputFile} \
			~{default="" "-t " + refFai} \
			~{default="" "-L " + bed} \
			~{default="" "-r " + readGroup} \
			~{default="" "-R " + readGroupFile} \
			-q ~{minQuality} \
			~{default="" "-l " + library} \
			-m ~{minCigarOp} \
			~{true="-M" false="" multiRegioOperator} \
			~{true="-B" false="" collapseCigarOp} \
			--output-fmt ~{ext} \
			~{default="" "--reference " + refFasta} \
			--threads ~{threads - 1} \
			~{in}

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
			description: 'Path used as executable [default: "samtools"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where index was generated. [default: pwd()]',
			category: 'Tool option'
		}
		name: {
			description: 'Name to use for output file name [default: basename(in)]',
			category: 'Tool option'
		}
		in: {
			description: 'Fasta file.',
			category: 'Required'
		}
		cram: {
			description: 'Output to cram format. (bam otherwise) [default: false]',
			category: 'Tool option'
		}
		refFai: {
			description: 'Listing reference names and lengths (fasta index)',
			category: 'Tool option'
		}
		bed: {
			description: 'Only include reads overlapping this BED FILE',
			category: 'Tool option'
		}
		readGroup: {
			description: 'Only include reads in read group.',
			category: 'Tool option'
		}
		readGroupFile: {
			description: 'Only include reads with read group listed in a file',
			category: 'Tool option'
		}
		minQuality: {
			description: 'Only include reads with mapping quality >= value [default: 0]',
			category: 'Tool option'
		}
		library: {
			description: 'Only include reads in library.',
			category: 'Tool option'
		}
		minCigarOp: {
			description: 'Only include reads with number of CIGAR operations consuming query sequence >= value [default: 0]',
			category: 'Tool option'
		}
		multiRegioOperator: {
			description: 'Use the multi-region iterator (increases the speed, removes duplicates and outputs the reads as they are ordered in the file) [default: false]',
			category: 'Tool option'
		}
		collapseCigarOp: {
			description: 'Collapse the backward CIGAR operation [default: false]',
			category: 'Tool option'
		}
		refFasta: {
			description: 'Reference sequence FASTA FILE [null]',
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

task faidx {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-08-05"
	}

	input {
		String path_exe = "samtools"

		File in
		String? outputPath
		String? name

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
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}.fai" else "~{baseName}.fai"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} faidx ~{in}
		mv ~{in + ".fai"} ~{outputFile}

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
			description: 'Path used as executable [default: "samtools"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where index was generated. [default: pwd()]',
			category: 'Tool option'
		}
		name: {
			description: 'Name to use for output file name [default: basename(in)]',
			category: 'Tool option'
		}
		in: {
			description: 'Fasta file.',
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

task fqidx {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-08-07"
	}

	input {
		String path_exe = "samtools"

		File in
		String? outputPath
		String? name

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
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}.fai" else "~{baseName}.fai"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} fqidx ~{in}
		mv ~{in + ".fai"} ~{outputFile}

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
			description: 'Path used as executable [default: "samtools"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where index was generated. [default: pwd()]',
			category: 'Tool option'
		}
		name: {
			description: 'Name to use for output file name [default: basename(in)]',
			category: 'Tool option'
		}
		in: {
			description: 'Fastq file.',
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

task flagstat {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-07-31"
	}

	input {
		String path_exe = "samtools"

		File in
		String? outputPath
		String? sample
		String ext = ".flagstats"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String sampleName = if defined(sample) then sample else sub(basename(in),"(\.bam|\.sam|\.cram)","")
	String outputFile = if defined(outputPath) then "~{outputPath}/~{sampleName}~{ext}" else "~{sampleName}~{ext}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} flagstat \
			--threads ~{threads - 1} \
			~{in} > ~{outputFile}

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
			description: 'Path used as executable [default: "samtools"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where flagstat file was generated. [default: pwd()]',
			category: 'Tool option'
		}
		sample: {
			description: 'Sample name to use for output file name [default: sub(basename(in),"(\.bam|\.sam|\.cram)","")]',
			category: 'Tool option'
		}
		in: {
			description: 'Bam file to sort.',
			category: 'Required'
		}
		ext: {
			description: 'Extension of the output file [default: ".flagstats"]',
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

task bedcov {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-07-30"
	}

	input {
		String path_exe = "samtools"

		File inBam
		File? inBamIdx
		File inBed
		String? outputPath
		String? name
		String suffix = ".bedcov"

		Int qualityThreshold = 0
		Boolean includeDel = true

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else sub(basename(inBam),"\.(sam|bam|cram)","")
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{suffix}.bed" else "~{baseName}~{suffix}.bed"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} bedcov \
			-Q ~{qualityThreshold} \
			~{true="" false="-j" includeDel} \
			~{inBed} \
			~{inBam} > ~{outputFile}

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
			description: 'Path used as executable [default: "samtools"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where bedcov file will be generated. [default: pwd()]',
			category: 'Tool option'
		}
		name: {
			description: 'Name to use for output file name [default: basename(in)]',
			category: 'Tool option'
		}
		inBed: {
			description: 'Bed file.',
			category: 'Required'
		}
		inBam: {
			description: 'Bam file.',
			category: 'Required'
		}
		inBamIdx: {
			description: 'Index of the input bam file.',
			category: 'Tool option'
		}
		suffix: {
			description: 'Suffix to add on the output file (e.g. sample.bedcov.bed) [default: ".bedcov"]',
			category: 'Tool option'
		}
		qualityThreshold: {
			description: 'Mapping quality threshold [default: 0]',
			category: 'Tool option'
		}
		includeDel: {
			description: 'Include deletions (D) and ref skips (N) in bedcov computation [default: true]',
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

task markdup {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-08-11"
	}

	input {
		String path_exe = "samtools"

		File in
		String? outputPath
		String? name
		String? outExt
		String? outputOpt
		String suffix = ".markdup"

		Boolean remove = false
		Int maxReadsLength = 300
		Boolean markSupAl = false
		Boolean reportStat = false
		Boolean markPrimDup = false

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String ext = if defined(outExt) then outExt else sub(basename(in),"(.*)\.(sam|bam|cram)$","$2")
	String baseName = if defined(name) then name else sub(basename(in),"(.*)\.(sam|bam|cram)$","$1")
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{suffix}.~{ext}" else "~{baseName}~{suffix}.~{ext}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} markdup \
			~{true="-r" false="" remove} \
			-l ~{maxReadsLength} \
			~{true="-S" false="" markSupAl} \
			~{true="-s" false="" reportStat} \
			~{true="-t" false="" markPrimDup} \
			--output-fmt ~{ext}~{default="" "," + outputOpt} \
			--threads ~{threads - 1} \
			~{in} \
			~{outputFile}

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
			description: 'Path used as executable [default: "samtools"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where bedcov file will be generated. [default: pwd()]',
			category: 'Output path/name option'
		}
		name: {
			description: 'Name to use for output file name [default: basename(in)]',
			category: 'Output path/name option'
		}
		outExt: {
			description: 'Specify output format (SAM, BAM, CRAM) [default: same as input]',
			category: 'Output path/name option'
		}
		in: {
			description: 'Bam file.',
			category: 'Required'
		}
		suffix: {
			description: 'Suffix to add on the output file (e.g. sample.markdup.bam) [default: ".markdup"]',
			category: 'Output path/name option'
		}
		outputOpt: {
			description: 'Specify output file format option in the form',
			category: 'Tool option'
		}
		remove: {
			description: 'Remove duplicates instead of just marking them [default: false]',
			category: 'Tool option'
		}
		maxReadsLength: {
			description: 'Max read length [default: 300]',
			category: 'Tool option'
		}
		markSupAl: {
			description: 'Mark supplemenary alignments of duplicates as duplicates (slower) [default: false]',
			category: 'Tool option'
		}
		reportStat: {
			description: 'Report stats. [default: false]',
			category: 'Tool option'
		}
		markPrimDup: {
			description: 'Mark primary duplicates with the name of the original in a "do" tag. [default: false]',
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

task fixmate {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-08-11"
	}

	input {
		String path_exe = "samtools"

		File in
		String? outputPath
		String? name
		String? outExt
		String? outputOpt
		String suffix = ".fixmate"

		Boolean remove = false
		Boolean disableFR = false
		Boolean addTemplateCigar = false
		Boolean addMateScoreTag = false

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String ext = if defined(outExt) then outExt else sub(basename(in),"(.*)\.(sam|bam|cram)$","$2")
	String baseName = if defined(name) then name else sub(basename(in),"(.*)\.(sam|bam|cram)$","$1")
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{suffix}.~{ext}" else "~{baseName}~{suffix}.~{ext}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} fixmate \
			~{true="-r" false="" remove} \
			~{true="-p" false="" disableFR} \
			~{true="-c" false="" addTemplateCigar} \
			~{true="-m" false="" addMateScoreTag} \
			--output-fmt ~{ext}~{default="" "," + outputOpt} \
			--threads ~{threads - 1} \
			~{in} \
			~{outputFile}

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
			description: 'Path used as executable [default: "samtools"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where bedcov file will be generated. [default: pwd()]',
			category: 'Tool option'
		}
		name: {
			description: 'Name to use for output file name [default: basename(in)]',
			category: 'Tool option'
		}
		outExt: {
			description: 'Specify output format (SAM, BAM, CRAM) [default: same as input]',
			category: 'Tool option'
		}
		in: {
			description: 'Bam file.',
			category: 'Required'
		}
		suffix: {
			description: 'Suffix to add on the output file (e.g. sample.markdup.bam) [default: ".fixmate"]',
			category: 'Tool option'
		}
		outputOpt: {
			description: 'Specify output file format option in the form',
			category: 'Tool option'
		}
		remove: {
			description: 'Remove unmapped reads and secondary alignments [default: false]',
			category: 'Tool option'
		}
		disableFR: {
			description: 'Disable FR proper pair check [default: false]',
			category: 'Tool option'
		}
		addTemplateCigar: {
			description: 'Add template cigar ct tag [default: false]',
			category: 'Tool option'
		}
		addMateScoreTag: {
			description: 'Add mate score tag [default: false]',
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

task merge {
	meta {
		author: "Olivier ardouin"
		email: "o-ardouin(at)chu-montpellier.fr"
		version: "0.0.2"
		date: "2020-09-18"
	}

	input {
		String path_exe = "samtools"

		Array[File] inputPaths
		Boolean outIndex = false
		String? outputPath
		String? name
		String ext = "cram"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else "samtools.merged"
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}.~{ext}" else "~{baseName}.~{ext}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} merge \
			--output-fmt ~{ext} \
			--threads ~{threads} \
			~{true="--write-index" false="" outIndex} \
			~{outputFile} \
			~{sep=" " inputPaths}

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
			description: 'Path used as executable [default: "samtools"]',
			category: 'System'
		}
		inputPaths: {
			description: 'Path array of input alignement files to merge',
			category: 'Required'
		}
		outIndex: {
			description: 'Automatically index the outputFile. [default: false]',
			category: 'Tool option'
		}
		outputPath: {
			description: 'Output path where merged alignement file will be generated. [default: pwd()]',
			category: 'Tool option'
		}
		name: {
			description: 'Name to use for output file name [default: basename(out)]',
			category: 'Tool option'
		}
		ext: {
			description: 'Specify output format (SAM, BAM, CRAM) [default: cram]',
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

task depth {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.4"
		date: "2021-05-12"
	}

	input {
		String path_exe = "samtools"

		File in
		File idx
		String? outputPath
		String? name
		String subString = ".bam"
		String subStringReplace = ""
		String ext = ".depth.txt"

		Boolean includeZero = false
		Boolean includeAll = false

		File? bed
		Boolean header = false

		Int minReadLen = 0
		Int maxDepth = 8000
		Int baseQualityMin = 0
		Int mappingQualityMin = 0
		Array[Int] includeFlag = [0]
		Array[String] excludeFlag = ["UNMAP","SECONDARY","QCFAIL","DUP"]

		File? refFasta

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else sub(basename(in),subString,subStringReplace)
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{ext}" else "~{baseName}~{ext}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} depth \
			~{true="-a " false ="" includeZero} \
			~{true="-aa " false ="" includeAll} \
			~{default="" "-b " + bed} \
			~{true="-H " false="" header} \
			-l ~{minReadLen} \
			-d ~{maxDepth} \
			-q ~{baseQualityMin} \
			-Q ~{mappingQualityMin} \
			-g ~{default="" sep="," includeFlag} \
			-G ~{default="" sep="," excludeFlag} \
			~{default="" "--reference " + refFasta} \
			-o ~{outputFile} \
			~{in}

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
			description: 'Path used as executable [default: "samtools"]',
			category: 'System'
		}
		in: {
			description: "File used as input",
			category: 'Required'
		}
		outputPath: {
			description: 'Output path',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output name',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Substring to edit from input file to create output [default: ".bam"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'Substring used to edit input file [default: ""]',
			category: 'Output path/name option'
		}
		ext: {
			description: 'Specify output extension [default: ".depth.txt"]',
			category: 'Tool option'
		}
		includeZero: {
			description: 'Output all positions (including zero depth) [default: false]',
			category: 'Tool option'
		}
		includeAll: {
			description: 'Output absolutely all positions, including unused ref. sequences [default: false]',
			category: 'Tool option'
		}
		bed: {
			description: 'List of positions or regions',
			category: 'Tool option'
		}
		header: {
			description: 'Print a file header [default: false]',
			category: ''
		}
		minReadLen: {
			description: 'Read length threshold (ignore reads shorter than <int>) [default: 0]',
			category: 'Tool option'
		}
		maxDepth: {
			description: 'Maximum coverage depth . If 0, depth is set to the maximum. [default: 8000]',
			category: 'Tool option'
		}
		baseQualityMin: {
			description: 'Base quality threshold [default: 0]',
			category: 'Tool option'
		}
		mappingQualityMin: {
			description: 'Mapping quality threshold [default: 0]',
			category: 'Tool option'
		}
		includeFlag: {
			description: 'Include reads that have any of the specified flags set [default: 0]',
			category: 'Tool option'
		}
		excludeFlag: {
			description: 'Filter out reads that have any of the specified flags set [default: UNMAP,SECONDARY,QCFAIL,DUP]',
			category: 'Tool option'
		}
		refFasta: {
			description: 'Reference sequence FASTA FILE',
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
