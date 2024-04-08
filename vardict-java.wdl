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

task vardictSoloAmplicons {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.4"
		date: "2021-05-14"
	}

	input {
		String path_exe = "vardict-java"

		File in
		File index
		String? outputPath
		String? name
		String suffix = ".vardict"
		String ext = ".txt"
		String subString = ".bam"
		String subStringReplace = ""

		File refFasta
		File refFai

		File target

		Int columnChr = 1
		Int columnStart = 2
		Int? columnSegStart
		Int columnEnd = 3
		Int? columnSegEnd
		Int columnAnn = 4
		String delimiter = "\"\\t\""
		Boolean zeroBased = false

		Boolean threePrimeIndels = false
		Int ampMaxEdges = 10
		Float ampMinOverlapPercent = 0.95
		Int STD = 4
		Int minReadsSB = 2
		Float thresholdAF = 0.01
		Int minVarReads = 2
		Int indelSize = 50
		Boolean localRealignment = true
		Float thresholdAFMonomerMS = 0.25
		Float thresholdAFNonmonomerMS = 0.1
		Float lowFreqNorm = 0.05
		Int? trimBasesAfter

		Boolean SVcalling = true
		Int minSVLenPres = 1000
		Int insertSizeSTD = 100
		Int insertSize = 300

		Boolean delDupVar = false
		Boolean rmDup = false
		String? hexFilter
		Int minMatches = 0
		Int maxMismatches = 8

		Int phredBase = 25
		Float minMeanMapQ = 0
		Float qRatio = 1.5
		Int? minMapQuality

		Boolean includeNDP = false
		Float meanPosition = 5
		Int extIndels = 2
		Int extSeg = 0
		Int extRef = 1200

		Boolean uniqueModeForward = false
		Boolean uniqueModeFirst = false

		Array[String]? adaptors
		Boolean chimericFilter = true
		Boolean spliceOut = false
		Boolean fisher = false
		Boolean header = false
		String validationMode = "LENIENT"
		Boolean pileup = false
		Float? downsampling

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
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{suffix}~{ext}" else "~{baseName}~{suffix}~{ext}"

	Boolean defAdaptors = defined(adaptors)

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} \
			-b ~{in} \
			-G ~{refFasta} \
			-c ~{columnChr} \
			-S ~{columnStart} \
			~{default="" "-s " + columnSegStart} \
			-E ~{columnEnd} \
			~{default="" "-e " + columnSegEnd} \
			-g ~{columnAnn} \
			-d ~{delimiter} \
			-z ~{true="1" false="0" zeroBased} \
			-N ~{baseName} \
			~{true="-3" false="" threePrimeIndels} \
			--amplicon ~{ampMaxEdges}:~{ampMinOverlapPercent} \
			-A ~{STD} \
			-B ~{minReadsSB} \
			-f ~{thresholdAF} \
			-r ~{minVarReads} \
			-I ~{indelSize} \
			-k ~{true="1" false="0" localRealignment} \
			-mfreq ~{thresholdAFMonomerMS} \
			-nmfreq ~{thresholdAFNonmonomerMS} \
			-V ~{lowFreqNorm} \
			~{default="" "--trim" + trimBasesAfter} \
			~{true="" false="--nosv" SVcalling} \
			-L ~{minSVLenPres} \
			--insert-std ~{insertSizeSTD} \
			--insert-size ~{insertSize} \
			~{true="-deldupvar" false="" delDupVar} \
			~{true="--dedup" false="" rmDup} \
			-F ~{default="0" hexFilter} \
			-M ~{minMatches} \
			-m ~{maxMismatches} \
			-q ~{phredBase} \
			-O ~{minMeanMapQ} \
			-o ~{qRatio} \
			~{default="" "-Q " + minMapQuality} \
			~{true="-K" false="" includeNDP} \
			-P ~{meanPosition} \
			-X ~{extIndels} \
			-x ~{extSeg} \
			-Y ~{extRef} \
			~{true="-u" false="" uniqueModeForward} \
			~{true="-UN" false="" uniqueModeFirst} \
			~{true="-adaptor " false="" defAdaptors}~{default="" sep="," adaptors} \
			~{true="" false="-chimeric" chimericFilter} \
			~{true="--splice" false="" spliceOut} \
			~{true="-fisher" false="" fisher} \
			~{true="--header" false="" header} \
			-VS ~{validationMode} \
			~{true="-p" false="" pileup} \
			~{default="" "-Z " + downsampling} \
			-th ~{threads} \
			~{target} > ~{outputFile}

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
			description: 'Path used as executable [default: "vardict-java"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where files were generated. [default: pwd()]',
			category: 'Output path/name option'
		}
		name: {
			description: 'Name to use for output file name [default: sub(basename(in),subString,subStringReplace)]',
			category: 'Output path/name option'
		}
		in: {
			description: 'Input reads (format: fastq, fastq.gz)',
			category: 'Required'
		}
		suffix: {
			description: 'Suffix to add to the output [default: .adaptersTrim]',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Extension to remove from the input file [default: "(_S[0-9]+)?(_L[0-9][0-9][0-9])?(_R[12])?(_[0-9][0-9][0-9])?.(fastq|fq)(.gz)?"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'subString replace by this string [default: ""]',
			category: 'Output path/name option'
		}
		refFasta: {
			description: 'Reference in fasta format',
			category: 'Required'
		}
		refFai: {
			description: 'Path to the reference file index (format: fai)',
			category: 'Required'
		}
		target: {
			description: 'The target region accept bed files by default (or refGene.txt from IGV, but can be any region). [default: ]',
			category: 'Required'
		}
		columnChr: {
			description: 'The column for chromosome [default: 1]',
			category: 'Tool option'
		}
		columnStart: {
			description: 'The column for region start [default: 2]',
			category: 'Tool option'
		}
		columnSegStart: {
			description: 'The column for segment starts in the region.',
			category: 'Tool option'
		}
		columnEnd: {
			description: 'The column for region end. [default: 3]',
			category: 'Tool option'
		}
		columnSegEnd: {
			description: 'The column for segment ends in the region.',
			category: 'Tool option'
		}
		columnAnn: {
			description: 'The column for region annotation [default: 4]',
			category: 'Tool option'
		}
		delimiter: {
			description: 'The delimiter for split region_info [default: "\n"]',
			category: 'Tool option'
		}
		zeroBased: {
			description: 'Indicate whether coordinates are zero-based, as IGV uses. [default: false]',
			category: 'Tool option'
		}
		threePrimeIndels: {
			description: 'Indicate to move indels to 3-prime if alternative alignment can be achieved. [default: false]',
			category: 'Tool option'
		}
		ampMaxEdges: {
			description: 'A read pair is considered belonging to the amplicon if the edges are less than int bp to the amplicon [default: 10]',
			category: 'Tool option'
		}
		ampMinOverlapPercent: {
			description: 'A read pair is considered belonging to the amplicon if overlap fraction is at least float. [default: 0.95]',
			category: 'Tool option'
		}
		STD: {
			description: 'The number of STD. A pair will be considered for DEL if INSERT > INSERT_SIZE + INSERT_STD_AMT * INSERT_STD. [default: 4]',
			category: 'Tool option'
		}
		minReadsSB: {
			description: 'The minimum # of reads to determine strand bias [default: 2]',
			category: 'Tool option'
		}
		thresholdAF: {
			description: 'The threshold for allele frequency [default: 0.01]',
			category: 'Tool option'
		}
		minVarReads: {
			description: 'The minimum # of variant reads [default: 2]',
			category: 'Tool option'
		}
		indelSize: {
			description: 'The indel size. [default: 50]',
			category: 'Tool option'
		}
		localRealignment: {
			description: 'Indicate whether to perform local realignment. (not recommanded for PacBio and Ion) [default: true]',
			category: 'Tool option'
		}
		thresholdAFMonomerMS: {
			description: 'The variant frequency threshold to determine variant as good in case of monomer MSI. [default: 0.25]',
			category: 'Tool option'
		}
		thresholdAFNonmonomerMS: {
			description: 'The variant frequency threshold to determine variant as good in case of non-monomer MSI. [default: 0.1]',
			category: 'Tool option'
		}
		lowFreqNorm: {
			description: 'The lowest frequency in the normal sample allowed for a putative somatic mutation. [default: 0.05]',
			category: 'Tool option'
		}
		trimBasesAfter: {
			description: 'Trim bases after N bases in the reads',
			category: 'Tool option'
		}
		SVcalling: {
			description: 'Turn on/off structural variant calling. [default: true]',
			category: 'Tool option'
		}
		minSVLenPres: {
			description: 'The minimum structural variant length to be presented using <DEL> <DUP> <INV> <INS>... [default: 1000]',
			category: 'Tool option'
		}
		insertSizeSTD: {
			description: 'The insert size STD. Used for SV calling. [default: 100]',
			category: 'Tool option'
		}
		insertSize: {
			description: 'The insert size. Used for SV calling. [default: 300]',
			category: 'Tool option'
		}
		delDupVar: {
			description: 'Turn on deleting of duplicate variants. Variants in this mode are considered and outputted only if start position of variant is inside the region interest. [default: false]',
			category: 'Tool option'
		}
		rmDup: {
			description: 'Indicate to remove duplicated reads. Only one pair with same start positions will be kept. [default: false]',
			category: 'Tool option'
		}
		hexFilter: {
			description: 'The hexical to filter reads using samtools (e.g. 0x504 (filter 2nd alignments, unmapped reads andduplicates).)',
			category: 'Tool option'
		}
		minMatches: {
			description: 'The minimum matches for a read to be considered. [default: 0]',
			category: 'Tool option'
		}
		maxMismatches: {
			description: 'Reads with more than N mismatches will be filtered and ignored. [default: 8]',
			category: 'Tool option'
		}
		phredBase: {
			description: 'The phred score for a base to be considered a good call. [default: 25]',
			category: 'Tool option'
		}
		minMeanMapQ: {
			description: 'The reads should have at least mean MapQ to be considered a valid variant. [default: 0]',
			category: 'Tool option'
		}
		qRatio: {
			description: ' The Qratio of (good_quality_reads)/(bad_quality_reads+0.5). The quality is defined by phredBase option. [default: 1.5]',
			category: 'Tool option'
		}
		minMapQuality: {
			description: 'If set, reads with mapping quality less than N will be filtered and ignored.',
			category: 'Tool option'
		}
		includeNDP: {
			description: 'Include Ns in the total depth calculation. [default: false]',
			category: 'Tool option'
		}
		meanPosition: {
			description: 'The read position filter. If the mean variants position is less that specified, it is considered false positive. [default: 5]',
			category: 'Tool option'
		}
		extIndels: {
			description: 'Extension of bp to look for mismatches after insersion or deletion. [default: 2]',
			category: 'Tool option'
		}
		extSeg: {
			description: 'The number of nucleotide to extend for each segment. [default: 0]',
			category: 'Tool option'
		}
		extRef: {
			description: 'Extension of bp of reference to build lookup table. [default: 1200]',
			category: 'Tool option'
		}
		uniqueModeForward: {
			description: 'Indicate unique mode, which when mate pairs overlap, the overlapping part will be counted only once using forward read only. [default: false]',
			category: 'Tool option'
		}
		uniqueModeFirst: {
			description: 'Indicate unique mode, which when mate pairs overlap, the overlapping part will be counted only once using first read only. [default: false]',
			category: 'Tool option'
		}
		adaptors: {
			description: 'Filter adaptor sequences so that they are not used in realignment.',
			category: 'Tool option'
		}
		chimericFilter: {
			description: 'Turn on/off chimeric reads filtering. [default: true]',
			category: 'Tool option'
		}
		spliceOut: {
			description: 'Output splicing read counts [default: false]',
			category: 'Tool option'
		}
		fisher: {
			description: 'Experimental feature: Changes R script (teststrandbias.R and testsomatic.) to Java implementation of Fisher exact test. [default: false]',
			category: 'Tool option'
		}
		header: {
			description: 'Print a header row describing columns [default: false]',
			category: 'Tool option'
		}
		validationMode: {
			description: 'How strict to be when reading a SAM or BAM. (choices: STRICT, LENIENT, SILENT) [default: "LENIENT"]',
			category: 'Tool option'
		}
		pileup: {
			description: 'Do pileup regardless of the frequency [default: false]',
			category: 'Tool option'
		}
		downsampling: {
			description: 'For downsampling fraction. e.g. 0.7 means roughly 70% downsampling.',
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

task teststrandbias {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.2"
		date: "2021-05-10"
	}

	input {
		String path_exe = "teststrandbias.R"

		File in
		String? outputPath
		String? name
		String subString = ".txt"
		String subStringReplace = ".strandbias.txt"

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
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}" else "~{baseName}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		cat ~{in} | ~{path_exe} > ~{outputFile}

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
			description: 'Path used as executable [default: "teststrandbias.R"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where files were generated. [default: pwd()]',
			category: 'Output path/name option'
		}
		name: {
			description: 'Name to use for output file name [default: sub(basename(in),subString,subStringReplace)]',
			category: 'Output path/name option'
		}
		in: {
			description: 'Output of vardict-java.',
			category: 'Required'
		}
		subString: {
			description: 'Extension to remove from the input file [default: ".txt"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'subString replace by this string [default: ".strandbias.txt"]',
			category: 'Output path/name option'
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

task var2vcf_valid {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.2"
		date: "2021-05-11"
	}

	input {
		String path_exe = "var2vcf_valid.pl"

		File in
		File index
		String? outputPath
		String? name
		String ext = ".vcf"
		String suffix = ".vardict"
		String subString = ".vardict.strandbias.txt"
		String subStringReplace = ""

		File refFasta
		File refFai

		File target

		Boolean amplicon = true
		Boolean hardFiltering = false
		Boolean allVar = true
		Int? filterNeighbour
		Int MS = 12
		Float maxMeanMismatches = 5.25
		Float meanPosition = 8
		Boolean positionSTD = false
		Float minBaseQuality = 22.5
		Float minMapQualityVar = 10
		Int minTotalDepth = 3
		Int minHQVarDepth = 2
		Float thresholdAF = 0.02
		Float minSignalNoise = 1.5
		Float minAFHomozygous = 0.2
		Boolean endTag = false
		Int minSplitReadsSV = 1

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
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{suffix}~{ext}" else "~{baseName}~{suffix}~{ext}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		cat ~{in} | ~{path_exe} \
			-b ~{target} \
			-G ~{refFasta} \
			-N ~{baseName} \
			~{true="-a" false="" amplicon} \
			~{true="-A" false="" allVar} \
			-d ~{minTotalDepth} \
			-v ~{minHQVarDepth} \
			-f ~{thresholdAF} \
			-F ~{minAFHomozygous} \
			-T ~{minSplitReadsSV} \
			~{true="-S" false="" hardFiltering} \
			~{default="" "-c" + filterNeighbour} \
			-m ~{maxMeanMismatches} \
			-p ~{meanPosition} \
			-P ~{true="1" false="0" positionSTD} \
			-q ~{minBaseQuality} \
			-Q ~{minMapQualityVar} \
			-o ~{minSignalNoise} \
			-I ~{MS} \
			~{true="" false="-E" endTag} \
			> ~{outputFile}

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
			description: 'Path used as executable [default: "var2vcf_valid.pl"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where files were generated. [default: pwd()]',
			category: 'Output path/name option'
		}
		name: {
			description: 'Name to use for output file name [default: sub(basename(in),subString,subStringReplace)]',
			category: 'Output path/name option'
		}
		in: {
			description: 'Input reads (format: fastq, fastq.gz)',
			category: 'Required'
		}
		suffix: {
			description: 'Suffix to add to the output [default: .adaptersTrim]',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Extension to remove from the input file [default: "(_S[0-9]+)?(_L[0-9][0-9][0-9])?(_R[12])?(_[0-9][0-9][0-9])?.(fastq|fq)(.gz)?"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'subString replace by this string [default: ""]',
			category: 'Output path/name option'
		}
		refFasta: {
			description: 'Reference in fasta format',
			category: 'Required'
		}
		refFai: {
			description: 'Path to the reference file index (format: fai)',
			category: 'Required'
		}
		target: {
			description: 'The target region accept bed files by default (or refGene.txt from IGV, but can be any region). [default: ]',
			category: 'Required'
		}
		amplicon: {
			description: 'Set on/off amplicon based variant calling. [default: true]',
			category: 'Tool option'
		}
		hardFiltering: {
			description: 'Sets on/off hard filtering variants (only variant in PASS) [default: false]',
			category: 'Tool option'
		}
		allVar: {
			description: 'Indicate to output all variants at the same position. [default: true]',
			category: 'Tool option'
		}
		filterNeighbour: {
			description: 'If two seemingly high quality SNV variants are within {int} bp, they are both filtered.',
			category: 'Tool option'
		}
		MS: {
			description: 'The maximum non-monomer MSI allowed for a HT variant with AF < 0.5. [default: 12]',
			category: 'Tool option'
		}
		maxMeanMismatches: {
			description: 'The maximum mean mismatches allowed. [default: 5.25]',
			category: 'Tool option'
		}
		meanPosition: {
			description: 'The minimum mean position of variants in the read. [default: 8]',
			category: 'Tool option'
		}
		positionSTD: {
			description: 'Tag variant with filter "PSTD" if variants have position SD bias in reads [default: false]',
			category: 'Tool option'
		}
		minBaseQuality: {
			description: 'The minimum mean base quality. [default: 22.5]',
			category: 'Tool option'
		}
		minMapQualityVar: {
			description: 'The minimum mapping quality. [default: 10]',
			category: 'Tool option'
		}
		minTotalDepth: {
			description: 'The minimum total depth. [default: 3]',
			category: 'Tool option'
		}
		minHQVarDepth: {
			description: 'The minimum high quality variant depth. [default: 2]',
			category: 'Tool option'
		}
		thresholdAF: {
			description: 'The minimum allele frequency. [default: 0.02]',
			category: 'Tool option'
		}
		minSignalNoise: {
			description: 'The minimum signal to noise, or the ratio of hi/(lo+0.5). [default: 1.5]',
			category: 'Tool option'
		}
		minAFHomozygous: {
			description: 'The minimum allele frequency to consider to be homozygous. [default: 0.2]',
			category: 'Tool option'
		}
		endTag: {
			description: 'Print END tag [default: true]',
			category: 'Tool option'
		}
		minSplitReadsSV: {
			description: 'The minimum number of split reads for SV. [default: 1]',
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
