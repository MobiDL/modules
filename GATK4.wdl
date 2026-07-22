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
		version: "0.1.0"
		date: "2026-07-16"
	}

	input {
		String path_exe = "gatk"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
		String apptainer_img = "GATK4:4.6.2.0"
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	command <<<
		~{path_exe} --version | head -2 | head -1
	>>>

	output {
		String version = read_string(stdout())
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
		docker: "~{apptainer_img}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
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
			description: 'Sets the apptainer image you want to use [default: GATK4:4.6.2.0]',
			category: 'System'
		}
	}
}

task reorderSam {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-07-27"
	}

	input {
		String path_exe = "gatk"
		Array[String]? javaOptions

		File in
		String? outputPath
		String? prefix
		String ext = ".bam"
		String suffix = "reorder"
		File sequenceDict

		Boolean allowIncompleteLengthDiscordance = false
		Boolean allowIncompleteDictDiscordance = false
		Int compressionLevel = 6
		Boolean createIndex = false
		Boolean createMD5 = false
		File? GA4GHClientSecrets
		Int maxRecordsInRam = 500000
		File? referenceSequence

		Boolean quiet = false
		File? tmpDir
		Boolean useJDKDeflater = false
		Boolean useJDKInflater = false
		String validationStringency = "STRICT"
		String verbosity = "INFO"
		Boolean showHidden = false

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String GA4GHClientSecretsOpt = if defined(GA4GHClientSecrets) then "--GA4GH_CLIENT_SECRETS ~{GA4GHClientSecrets} " else ""
	String referenceSequenceOpt = if defined(referenceSequence) then "--REFERENCE_SEQUENCE ~{referenceSequence} " else ""

	String outputName = if defined(prefix) then "~{prefix}.~{suffix}~{ext}" else basename(in,ext) + ".~{suffix}~{ext}"
	String outputFile = if defined(outputPath) then "~{outputPath}/~{outputName}" else "~{outputName}"

	command <<<

		if [[ ! -f ~{outputFile} ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} ReorderSam ~{GA4GHClientSecrets}~{referenceSequenceOpt} \
			--java-options '~{sep=" " javaOptions}' \
			--ALLOW_CONTIG_LENGTH_DISCORDANCE '~{allowIncompleteLengthDiscordance}' \
			--ALLOW_INCOMPLETE_DICT_CONCORDANCE '~{allowIncompleteDictDiscordance}' \
			--COMPRESSION_LEVEL ~{compressionLevel} \
			--CREATE_INDEX '~{createIndex}' \
			--CREATE_MD5_FILE '~{createMD5}' \
			--MAX_RECORDS_IN_RAM ~{maxRecordsInRam} \
			--QUIET '~{quiet}' \
			--TMP_DIR ~{default='null' tmpDir} \
			--USE_JDK_DEFLATER '~{useJDKDeflater}' \
			--USE_JDK_INFLATER '~{useJDKInflater}' \
			--VALIDATION_STRINGENCY '~{validationStringency}' \
			--VERBOSITY ~{verbosity} \
			--showHidden ~{showHidden} \
			--INPUT ~{in} \
			--SEQUENCE_DICTIONARY ~{sequenceDict} \
			--OUTPUT ~{outputFile}

	>>>

	output {
		File outputFile = "~{outputFile}"
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'Input file (SAM or BAM) to extract reads from..',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where file (SAM or BAM) were generated.',
			category: 'Output path/name option'
		}
		ext: {
			description: 'Extension of the input file (".sam" or ".bam") [default: ".bam"]',
			category: 'Tool option'
		}
		prefix: {
			description: 'Prefix for the output file [default: basename(in, ext)]',
			category: 'Output path/name option'
		}
		suffix: {
			description: 'Suffix for the output file (e.g. sample.suffix.bam) [default: "reorder"]',
			category: 'Output path/name option'
		}
		sequenceDict: {
			description: 'Sequence Dictionary for the OUTPUT file (can be read from one of the following file types (SAM, BAM, VCF, BCF, Interval List, Fasta, or Dict)',
			category: 'Required'
		}
		allowIncompleteLengthDiscordance: {
			description: 'If true, then permits mapping from a read contig to a new reference contig with the same name but a different length. Highly dangerous, only use if you know what you are doing. [Default: false]',
			category: 'Tool option'
		}
		allowIncompleteDictDiscordance: {
			description: 'If true, allows only a partial overlap of the original contigs with the new reference sequence contigs. By default, this tool requires a corresponding contig in the new reference for each read contig. [Default: false]',
			category: 'Tool option'
		}
		compressionLevel: {
			description: 'Compression level for all compressed files created (e.g. BAM and VCF). [default: 6]',
			category: 'Tool option'
		}
		createIndex: {
			description: 'Whether to create a BAM index when writing a coordinate-sorted BAM file. [Default: false]',
			category: 'Tool option'
		}
		createMD5: {
			description: 'Whether to create an MD5 digest for any BAM or FASTQ files created. [Default: false]',
			category: 'Tool option'
		}
		GA4GHClientSecrets: {
			description: 'Google Genomics API client_secrets.json file path. [Default: null]',
			category: 'Tool option'
		}
		maxRecordsInRam: {
			description: 'When writing files that need to be sorted, this will specify the number of records stored in RAM before spilling to disk. Increasing this number reduces the number of file handles needed to sort the file, and increases the amount of RAM needed. [Default: 500000]',
			category: 'Tool option'
		}
		referenceSequence: {
			description: 'Reference sequence file. [Default: null]',
			category: 'Tool option'
		}
		quiet: {
			description: 'Whether to suppress job-summary info on System.err. [Default: false]',
			category: 'Tool option'
		}
		tmpDir: {
			description: 'Path to a directory with space available to be used by this program for temporary storage of working files. [Default: null]',
			category: 'Tool option'
		}
		useJDKDeflater: {
			description: 'Use the JDK Deflater instead of the Intel Deflater for writing compressed output. [Default: false]',
			category: 'Tool option'
		}
		useJDKInflater: {
			description: 'Use the JDK Inflater instead of the Intel Inflater for reading compressed input. [Default: false]',
			category: 'Tool option'
		}
		validationStringency: {
			description: ' Validation stringency for all SAM files read by this program. Setting stringency to SILENT can improve performance when processing a BAM file in which variable-length data (read, qualities, tags) do not otherwise need to be decoded. [Default: "STRIC"]',
			category: 'Tool option'
		}
		verbosity: {
			description: 'Control verbosity of logging. [Default: "INFO"]',
			category: 'Tool option'
		}
		showHidden: {
			description: 'Display hidden arguments. [Default: false]',
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

### WARNING : depthOfCoverage is on BETA
## 		--calculate-coverage-over-genes,-gene-list: option seems not working
##			properly : https://github.com/broadinstitute/gatk/issues/6714
##		--count-type: only "COUNT_READS" is supported
task depthOfCoverage {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1b"
		date: "2020-07-27"
	}

	input {
		String path_exe = "gatk"
		Array[String]? javaOptions

		File in
		File bamIndex
		File intervals
		String? outputPath
		String? prefix
		String ext = ".bam"
		String suffix = "DoC"
		File referenceFasta
		File referenceFai
		File referenceDict

		File? geneList
		String countType = "COUNT_READS"
		Boolean disableBamIndexCaching = false
		Boolean disableSequenceDictionaryValidation = false
		String intervalMergingRule = "ALL"
		Int maxBaseQuality = 127
		Int minBaseQuality = 0
		Int maxDepthPerSample = 0
		String outputFormat = "CSV"
		String partitionType = "sample"
		Boolean printBaseCounts = false

		Boolean quiet = false
		File? tmpDir
		Boolean useJDKDeflater = false
		Boolean useJDKInflater = false
		String validationStringency = "SILENT"
		String verbosity = "INFO"
		Boolean showHidden = false

		Array[Int] summaryCoverageThreshold = [5]

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	Array[String] summaryCoverageThresholdOpt = prefix("--summary-coverage-threshold ", summaryCoverageThreshold)

	String outputName = if defined(prefix) then "~{prefix}.~{suffix}" else basename(in,ext) + ".~{suffix}"
	String outputFile = if defined(outputPath) then "~{outputPath}/~{outputName}" else "~{outputName}"

	command <<<

		if [[ ! -f ~{outputFile} ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} DepthOfCoverage \
			--java-options '~{sep=" " javaOptions}' \
			--calculate-coverage-over-genes ~{default='null' geneList} \
			--count-type ~{countType} \
			--disable-bam-index-caching ~{disableBamIndexCaching} \
			--disable-sequence-dictionary-validation ~{disableSequenceDictionaryValidation} \
			--interval-merging-rule ~{intervalMergingRule} \
			--max-base-quality ~{maxBaseQuality} \
			--max-depth-per-sample ~{maxDepthPerSample} \
			--min-base-quality ~{minBaseQuality} \
			--output-format ~{outputFormat} \
			--partition-type ~{partitionType} \
			--print-base-counts ~{printBaseCounts} \
			--QUIET '~{quiet}' \
			--use-jdk-deflater '~{useJDKDeflater}' \
			--use-jdk-inflater '~{useJDKInflater}' \
			--read-validation-stringency '~{validationStringency}' \
			--verbosity ~{verbosity} \
			--showHidden ~{showHidden} \
			--input ~{in} \
			--intervals ~{intervals} \
			--reference ~{referenceFasta} \
			--output ~{outputFile} \
			~{sep=" " summaryCoverageThresholdOpt}

	>>>

	output {
		File outputFile = "~{outputFile}"
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'BAM/SAM/CRAM file containing reads.',
			category: 'Required'
		}
		intervals: {
			description: 'Path to a file containing genomic intervals over which to operate. (format intervals list: chr1:1000-2000)',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where files were generated.',
			category: 'Output path/name option'
		}
		ext: {
			description: 'Extension of the input file (".sam" or ".bam") [default: ".bam"]',
			category: 'Tool option'
		}
		prefix: {
			description: 'Prefix for the output file [default: basename(in, ext)]',
			category: 'Output path/name option'
		}
		suffix: {
			description: 'Suffix for the output file (e.g. prefix.suffix.bam) [default: "DoC"]',
			category: 'Output path/name option'
		}
		referenceFasta: {
			description: 'Path to the reference file (format: fasta)',
			category: 'Required'
		}
		referenceFai: {
			description: 'Path to the reference file index (format: fai)',
			category: 'Required'
		}
		referenceDict: {
			description: 'Path to the reference file dict (format: dict)',
			category: 'Required'
		}
		geneList: {
			description: 'Calculate coverage statistics over this list of genes. (refseq format)',
			category: 'Tool option'
		}
		countType: {
			description: 'How should overlapping reads from the same fragment be handled? (Possible values: {COUNT_READS, COUNT_FRAGMENTS, COUNT_FRAGMENTS_REQUIRE_SAME_BASE}) [default: COUNT_READS]',
			category: 'Tool option'
		}
		disableBamIndexCaching: {
			description: "If true, don't cache bam indexes, this will reduce memory requirements but may harm performance if many intervals are specified. Caching is automatically disabled if there are no intervals specified. [default: false]",
			category: 'Tool option'
		}
		disableSequenceDictionaryValidation: {
			description: 'If specified, do not check the sequence dictionaries from our inputs for compatibility. Use at your own risk! [default: false]',
			category: 'Tool option'
		}
		intervalMergingRule: {
			description: 'Interval merging rule for abutting intervals. (possible values: ALL, OVERLAPPING_ONLY) [default: ALL]',
			category: 'Tool option'
		}
		maxBaseQuality: {
			description: 'Maximum quality of bases to count towards depth. [default: 127]',
			category: 'Tool option'
		}
		minBaseQuality: {
			description: 'Minimum quality of bases to count towards depth. [default: 0]',
			category: 'Tool option'
		}
		maxDepthPerSample: {
			description: 'Maximum number of reads to retain per sample per locus. Reads above this threshold will be downsampled. Set to 0 to disable. [default: 0]',
			category: 'Tool option'
		}
		outputFormat: {
			description: 'The format of the output file. (possible values: CSV, TABLE) [default: CSV]',
			category: 'Tool option'
		}
		partitionType: {
			description: 'Partition type for depth of coverage. (possbile values: sample, readgroup and/or library) [default: sample]',
			category: 'Tool option'
		}
		printBaseCounts: {
			description: 'Add base counts to per-locus output. [default: false]',
			category: 'Tool option'
		}
		quiet: {
			description: 'Whether to suppress job-summary info on System.err. [Default: false]',
			category: 'Tool option'
		}
		tmpDir: {
			description: 'Path to a directory with space available to be used by this program for temporary storage of working files. [Default: null]',
			category: 'Tool option'
		}
		useJDKDeflater: {
			description: 'Use the JDK Deflater instead of the Intel Deflater for writing compressed output. [Default: false]',
			category: 'Tool option'
		}
		useJDKInflater: {
			description: 'Use the JDK Inflater instead of the Intel Inflater for reading compressed input. [Default: false]',
			category: 'Tool option'
		}
		validationStringency: {
			description: ' Validation stringency for all SAM files read by this program. Setting stringency to SILENT can improve performance when processing a BAM file in which variable-length data (read, qualities, tags) do not otherwise need to be decoded. [Default: "STRIC"]',
			category: 'Tool option'
		}
		verbosity: {
			description: 'Control verbosity of logging. [Default: "INFO"]',
			category: 'Tool option'
		}
		showHidden: {
			description: 'Display hidden arguments. [Default: false]',
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

task splitIntervals {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.1.1"
		date: "2026-07-22"
	}

	input {
		String path_exe = "gatk"

		File bed
		String? outputPath
		String? name
		String subString = "\.([a-zA-Z]*)$"
		String subStringReplace = "-split"

		File refFasta
		File refFai = refFasta + ".fai"
		File refDict = sub(refFasta, "(.*).(fa|fasta)", "$1.dict")

		Int scatterCount = 1
		String subdivisionMode = "INTERVAL_SUBDIVISION"
		Int intervalsPadding = 0
		Boolean overlappingRule = false
		Boolean intersectionRule = false

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
		String apptainer_img = "gatk4:4.6.2.0"
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else sub(basename(bed),subString,subStringReplace)
	String outputRep = if defined(outputPath) then "~{outputPath}/~{baseName}" else "~{baseName}"

	command <<<

		if [[ ! -d $(dirname ~{outputRep}) ]]; then
			mkdir -p $(dirname ~{outputRep})
		fi

		~{path_exe} SplitIntervals \
			--intervals ~{bed} \
			--reference ~{refFasta} \
			--scatter-count ~{scatterCount} \
			--subdivision-mode ~{subdivisionMode} \
			--interval-padding ~{intervalsPadding} \
			--interval-merging-rule ~{true="OVERLAPPING_ONLY" false="ALL" overlappingRule} \
			--interval-set-rule ~{true="INTERSECTION" false="UNION" intersectionRule} \
			--output ~{outputRep}

	>>>

	output {
		Array[File] splittedIntervals = glob("~{outputRep}/*-scattered.interval_list")
	}

	runtime {
		bind_opt: "~{outputPath}" + "," + sub(refFasta,"(.*)\/(.*)$","$1") + "," + sub(bed,"(.*)\/(.*)$","$1")
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
		docker: "~{apptainer_img}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		bed: {
			description: 'Path to a file containing genomic intervals over which to operate. (format: bed or GATK intervals list)',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where files were generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output repertory name [default: sub(basename(in),"\.([a-zA-Z]*)$","")].',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Extension to remove from the input file [default: "\.([a-zA-Z]*)$"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'subString replace by this string [default: "-split"]',
			category: 'Output path/name option'
		}
		refFasta: {
			description: 'Path to the reference file (format: fasta)',
			category: 'Required'
		}
		refFai: {
			description: 'Path to the reference file index (format: fai)',
			category: 'Required'
		}
		refDict: {
			description: 'Path to the reference file dict (format: dict)',
			category: 'Required'
		}
		scatterCount: {
			description: 'Scatter count: number of output interval files to split into [default: 1]',
			category: 'Tool option'
		}
		subdivisionMode: {
			description: 'How to divide intervals {INTERVAL_SUBDIVISION, BALANCING_WITHOUT_INTERVAL_SUBDIVISION, BALANCING_WITHOUT_INTERVAL_SUBDIVISION_WITH_OVERFLOW, INTERVAL_COUNT}. [default: INTERVAL_SUBDIVISION]',
			category: 'Tool option'
		}
		intervalsPadding: {
			description: 'Amount of padding (in bp) to add to each interval you are including. [default: 0]',
			category: 'Tool option'
		}
		overlappingRule: {
			description: 'Interval merging rule for abutting intervals set to OVERLAPPING_ONLY [default: false => ALL]',
			category: 'Tool option'
		}
		intersectionRule: {
			description: 'Set merging approach to use for combining interval inputs to INTERSECTION [default: false => UNION]',
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
		apptainer_img: {
			description: 'Sets the apptainer image you want to use [default: gatk4:4.6.2.0]',
			category: 'System'
		}
	}
}

task baseRecalibrator {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.1.1"
		date: "2026-07-22"
	}

	input {
		String path_exe = "gatk"

		File bam
		File bai = bam + ".bai"
		String? outputPath
		String? name
		File? bed
		String subString_intervals = "([0-9]+)-scattered.interval_list"
		String subStringReplace_intervals = "$1"
		String ext = ".recal"

		Array[Pair[File, File]]+ knownSites

		File refFasta
		File refFai = refFasta + ".fai"
		File refDict = sub(refFasta, "(.*).(fa|fasta)", "$1.dict")

		Int gapPenality = 40
		Int indelDefaultQual = 45
		Int lowQualTail = 2
		Int indelKmer = 3
		Int mismatchKmer = 2
		Int maxCycle = 500

		Boolean overlappingRule = false
		Int intervalsPadding = 0
		Boolean intersectionRule = false

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
		String apptainer_img = "gatk4:4.6.2.0"
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseNameIntervals = if defined(bed) then bed else ""
	String baseIntervals = if defined(bed) then sub(basename(baseNameIntervals),subString_intervals,subStringReplace_intervals) else ""

	String baseName = if defined(name) then name else sub(basename(bam),"\.(sam|bam|cram)$","")
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}.~{baseIntervals}~{ext}" else "~{baseName}.~{baseIntervals}~{ext}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		for knownsite in $(jq -r '.[].left' ~{write_json(knownSites)}); do
			knownsites="${knownsites} --known-sites ${knownsite}"
		done

		~{path_exe} BaseRecalibrator \
			--input "~{bam}" \
			--reference "~{refFasta}" \
			~{default="" "--intervals " + bed} \
			${knownsites} \
			--bqsr-baq-gap-open-penalty ~{gapPenality} \
			--deletions-default-quality ~{indelDefaultQual} \
			--insertions-default-quality ~{indelDefaultQual} \
			--low-quality-tail ~{lowQualTail} \
			--indels-context-size ~{indelKmer} \
			--mismatches-context-size ~{mismatchKmer} \
			--maximum-cycle-value ~{maxCycle} \
			--interval-padding ~{intervalsPadding} \
			--interval-merging-rule ~{true="OVERLAPPING_ONLY" false="ALL" overlappingRule} \
			--interval-set-rule ~{true="INTERSECTION" false="UNION" intersectionRule} \
			--output "~{outputFile}"

	>>>

	output {
		File outputFile = outputFile
	}

	runtime {
		bind_opt: "~{outputPath}" + "," + sub(bam,"(.*)\/(.*)$","$1") + "," + sub(baseNameIntervals,"(.*)\/(.*)$","$1") + "," + sub(refFasta,"(.*)\/(.*)$","$1")
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
		docker: "~{apptainer_img}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		bam: {
			description: 'Alignement file to recalibrate (SAM/BAM/CRAM)',
			category: 'Required'
		}
		bed: {
			description: 'Path to a file containing genomic intervals over which to operate. (format: bed or GATK intervals list)',
			category: 'Tool option'
		}
		subString_intervals: {
			description: 'Substring to replace for intervals files (e.g. remove extension) [default: "([0-9]+)-scattered.interval_list"]',
			category: 'Output path/name option'
		}
		subStringReplace_intervals: {
			description: 'Substring used to replace for intervals files (e.g. add a suffix) [default: "$1"]',
			category: 'Output path/name option'
		}
		outputPath: {
			description: 'Output path where bqsr report will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(in),"\.(sam|bam|cram)$","")].',
			category: 'Output path/name option'
		}
		ext: {
			description: 'Extension for the output file [default: ".recal"]',
			category: 'Output path/name option'
		}
		knownSites: {
			description: 'One or more databases of known polymorphic sites used to exclude regions around known polymorphisms from analysis.',
			category: 'Tool option'
		}
		refFasta: {
			description: 'Path to the reference file (format: fasta)',
			category: 'Required'
		}
		refFai: {
			description: 'Path to the reference file index (format: fai)',
			category: 'Required'
		}
		refDict: {
			description: 'Path to the reference file dict (format: dict)',
			category: 'Required'
		}
		gapPenality: {
			description: 'BQSR BAQ gap open penalty (Phred Scaled). Default value is 40. 30 is perhaps better for whole genome call sets [default: 40]',
			category: 'Tool option'
		}
		indelDefaultQual: {
			description: 'Default quality for the base insertions/deletions covariate [default: 45]',
			category: 'Tool option'
		}
		lowQualTail: {
			description: 'Minimum quality for the bases in the tail of the reads to be considered [default: 2]',
			category: 'Tool option'
		}
		indelKmer: {
			description: 'Size of the k-mer context to be used for base insertions and deletions [default: 3]',
			category: 'Tool option'
		}
		mismatchKmer: {
			description: 'Size of the k-mer context to be used for base mismatches [default: 2]',
			category: 'Tool option'
		}
		maxCycle: {
			description: 'The maximum cycle value permitted for the Cycle covariate [default: 500]',
			category: 'Tool option'
		}
		intervalsPadding: {
			description: 'Amount of padding (in bp) to add to each interval you are including. [default: 0]',
			category: 'Tool option'
		}
		overlappingRule: {
			description: 'Interval merging rule for abutting intervals set to OVERLAPPING_ONLY [default: false => ALL]',
			category: 'Tool option'
		}
		intersectionRule: {
			description: 'Set merging approach to use for combining interval inputs to INTERSECTION [default: false => UNION]',
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
		apptainer_img: {
			description: 'Sets the apptainer image you want to use [default: gatk4:4.6.2.0]',
			category: 'System'
		}
	}
}

task gatherBQSRReports {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.2"
		date: "2020-12-23"
	}

	input {
		String path_exe = "gatk"

		Array[File]+ in
		String? outputPath
		String? name
		String subString = "(\.[0-9]+)?\.recal$"
		String subStringReplace = ""
		String ext = ".bqsr.report"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String firstFile = basename(in[0])
	String baseName = if defined(name) then name else sub(basename(firstFile),subString,subStringReplace)
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{ext}" else "~{baseName}~{ext}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} GatherBQSRReports \
			--input ~{sep=" --input " in} \
			--output ~{outputFile}

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
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'List of scattered BQSR report files',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where bqsr report will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(firstFile),subString,"")].',
			category: 'Output path/name option'
		}
		ext: {
			description: 'Extension for the output file [default: ".bqsr.report"]',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Extension to remove from the input file [default: "(\.[0-9]+)?\.recal$"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'Substring used to replace (e.g. add a suffix) [default: ""]',
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

task applyBQSR {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.2"
		date: "2021-02-23"
	}

	input {
		String path_exe = "gatk"

		File in
		File bamIdx
		File bqsrReport
		File? intervals
		String subString_intervals = "([0-9]+)-scattered.interval_list"
		String subStringReplace_intervals = "$1"
		String? outputPath
		String? name
		String suffix = ".bqsr"

		File refFasta
		File refFai
		File refDict

		Boolean originalQScore = false
		Int globalQScorePrior = -1
		Int preserveQScoreLT = 6
		Int quantizeQual = 0

		Boolean overlappingRule = false
		Int intervalsPadding = 0
		Boolean intersectionRule = false

		Boolean bamIndex = true
		Boolean bamMD5 = true

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseNameIntervals = if defined(intervals) then intervals else ""
	String baseIntervals = if defined(intervals) then sub(basename(baseNameIntervals),subString_intervals,subStringReplace_intervals) else ""

	String baseName = if defined(name) then name else sub(basename(in),"(.*)\.(sam|bam|cram)$","$1")
	String ext = sub(basename(in),"(.*)\.(sam|bam|cram)$","$2")
	String outputBamFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{suffix}.~{baseIntervals}\.~{ext}" else "~{baseName}~{suffix}.~{baseIntervals}\.~{ext}"
	String outputBaiFile = sub(outputBamFile,"(m)$","i")

	command <<<

		if [[ ! -d $(dirname ~{outputBamFile}) ]]; then
			mkdir -p $(dirname ~{outputBamFile})
		fi

		~{path_exe} ApplyBQSR \
			--input ~{in} \
			--bqsr-recal-file ~{bqsrReport} \
			--reference ~{refFasta} \
			~{default="" "--intervals " + intervals} \
			~{true="--emit-original-quals" false="" originalQScore} \
			--global-qscore-prior ~{globalQScorePrior} \
			--preserve-qscores-less-than ~{preserveQScoreLT} \
			--quantize-quals ~{quantizeQual} \
			--interval-padding ~{intervalsPadding} \
			--interval-merging-rule ~{true="OVERLAPPING_ONLY" false="ALL" overlappingRule} \
			--interval-set-rule ~{true="INTERSECTION" false="UNION" intersectionRule} \
			~{true="--create-output-bam-index" false="" bamIndex} \
			~{true="--create-output-bam-md5" false="" bamMD5} \
			--output ~{outputBamFile}

	>>>

	output {
		File outputBam = outputBamFile
		File outputBai = outputBaiFile
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'Bam file top apply BQSR.',
			category: 'Required'
		}
		bamIdx: {
			description: 'Index for the alignement input file to recalibrate.',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where bam will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(firstFile),subString,"")].',
			category: 'Output path/name option'
		}
		suffix: {
			description: 'Suffix to add for the output file (e.g sample.suffix.bam)[default: ".bqsr"]',
			category: 'Output path/name option'
		}
		bqsrReport: {
			description: 'Path to a file containing bqsr report',
			category: 'Required'
		}
		intervals: {
			description: 'Path to a file containing genomic intervals over which to operate. (format intervals list: chr1:1000-2000)',
			category: 'Tool option'
		}
		subString_intervals: {
			description: 'Substring to replace for intervals files (e.g. remove extension) [default: "([0-9]+)-scattered.interval_list"]',
			category: 'Output path/name option'
		}
		subStringReplace_intervals: {
			description: 'Substring used to replace for intervals files (e.g. add a suffix) [default: "$1"]',
			category: 'Output path/name option'
		}
		refFasta: {
			description: 'Path to the reference file (format: fasta)',
			category: 'Required'
		}
		refFai: {
			description: 'Path to the reference file index (format: fai)',
			category: 'Required'
		}
		refDict: {
			description: 'Path to the reference file dict (format: dict)',
			category: 'Required'
		}
		originalQScore: {
			description: 'Emit original base qualities under the OQ tag [default: false]',
			category: 'Tool option'
		}
		globalQScorePrior: {
			description: 'Global Qscore Bayesian prior to use for BQSR [default: -1]',
			category: 'Tool option'
		}
		preserveQScoreLT: {
			description: "Don't recalibrate bases with quality scores less than this threshold [default: 6]",
			category: 'Tool option'
		}
		quantizeQual: {
			description: 'Quantize quality scores to a given number of levels [default: 0]',
			category: 'Tool option'
		}
		intervalsPadding: {
			description: 'Amount of padding (in bp) to add to each interval you are including. [default: 0]',
			category: 'Tool option'
		}
		overlappingRule: {
			description: 'Interval merging rule for abutting intervals set to OVERLAPPING_ONLY [default: false => ALL]',
			category: 'Tool option'
		}
		intersectionRule: {
			description: 'Set merging approach to use for combining interval inputs to INTERSECTION [default: false => UNION]',
			category: 'Tool option'
		}
		bamIndex: {
			description: 'Create a BAM/CRAM index when writing a coordinate-sorted BAM/CRAM file [default: true]',
			category: 'Tool option'
		}
		bamMD5: {
			description: 'Create a MD5 digest for any BAM/SAM/CRAM file created [default: true]',
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

task gatherBamFiles {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.3"
		date: "2021-04-07"
	}

	input {
		String path_exe = "gatk"

		Array[File]+ in
		Array[File]+ bamIdx
		String? outputPath
		String? name
		String suffix = ".gather"
		String subString = "(\.[0-9]+)?\.(sam|bam|cram)$"
		String subStringReplace = ""

		Int compressionLevel = 6
		Boolean bamMD5 = true

		Int maxRecordsInRam = 500000

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String firstFile = basename(in[0])
	String baseName = if defined(name) then name else sub(basename(firstFile),subString,subStringReplace)
	String ext = sub(basename(in[0]),"(.*)\.(sam|bam|cram)$","$2")
	String outputBamFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{suffix}.~{ext}" else "~{baseName}~{suffix}.~{ext}"
	String outputBaiFile = sub(outputBamFile,"(m)$","i")

	command <<<

		if [[ ! -d $(dirname ~{outputBamFile}) ]]; then
			mkdir -p $(dirname ~{outputBamFile})
		fi

		~{path_exe} GatherBamFiles \
			--INPUT ~{sep=" --INPUT " in} \
			--COMPRESSION_LEVEL ~{compressionLevel} \
			--MAX_RECORDS_IN_RAM ~{maxRecordsInRam} \
			--CREATE_INDEX \
			~{true="--CREATE_MD5_FILE" false="" bamMD5} \
			--OUTPUT ~{outputBamFile}

	>>>

	output {
		File outputBam = outputBamFile
		File outputBai = outputBaiFile
		File? outputMD5 = outputBamFile + ".md5"
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'Array of BAMs to gather.',
			category: 'Required'
		}
		bamIdx: {
			description: 'Array of Index of alignements inputs files.',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where bam will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(firstFile),subString,"")].',
			category: 'Output path/name option'
		}
		suffix: {
			description: 'Suffix to add for the output file (e.g sample.suffix.bam)[default: ".gather"]',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Extension to remove from the input file [default: "(\.[0-9]+)?\.(sam|bam|cram)$"]',
			category: 'Output path/name option'
		}
		compressionLevel: {
			description: 'Compression level for all compressed files created (e.g. BAM and VCF). [default: 6]',
			category: 'Tool option'
		}
		maxRecordsInRam: {
			description: 'When writing files that need to be sorted, this will specify the number of records stored in RAM before spilling to disk. Increasing this number reduces the number of file handles needed to sort the file, and increases the amount of RAM needed. [Default: 500000]',
			category: 'Tool option'
		}
		bamMD5: {
			description: 'Create a MD5 digest for any BAM/SAM/CRAM file created [default: true]',
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

task leftAlignIndels {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-08-07"
	}

	input {
		String path_exe = "gatk"

		File in
		File bamIdx
		String? outputPath
		String? name
		String suffix = ".leftAlign"

		File? intervals

		File refFasta
		File refFai
		File refDict

		Boolean overlappingRule = false
		Int intervalsPadding = 0
		Boolean intersectionRule = false

		Boolean bamIndex = true
		Boolean bamMD5 = true

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseNameIntervals = if defined(intervals) then intervals else ""
	String baseIntervals = if defined(intervals) then sub(basename(baseNameIntervals),"([0-9]+)-scattered.interval_list","\.$1") else ""

	String baseName = if defined(name) then name else sub(basename(in),"(\.[0-9]+)?\.(sam|bam|cram)$","")
	String ext = sub(basename(in),"(.*)\.(sam|bam|cram)$","$2")
	String outputBamFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{suffix}~{baseIntervals}\.~{ext}" else "~{baseName}~{suffix}~{baseIntervals}\.~{ext}"
	String outputBaiFile = sub(outputBamFile,"(m)$","i")

	command <<<

		if [[ ! -d $(dirname ~{outputBamFile}) ]]; then
			mkdir -p $(dirname ~{outputBamFile})
		fi

		~{path_exe} LeftAlignIndels \
			--input ~{in} \
			--reference ~{refFasta} \
			--sequence-dictionary ~{refDict} \
			~{default="" "--intervals " + intervals} \
			--interval-padding ~{intervalsPadding} \
			--interval-merging-rule ~{true="OVERLAPPING_ONLY" false="ALL" overlappingRule} \
			--interval-set-rule ~{true="INTERSECTION" false="UNION" intersectionRule} \
			~{true="--create-output-bam-index" false="" bamIndex} \
			~{true="--create-output-bam-md5" false="" bamMD5} \
			--output ~{outputBamFile}

	>>>

	output {
		File outputBam = outputBamFile
		File outputBai = outputBaiFile
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'BAM to leftAlign.',
			category: 'Required'
		}
		bamIdx: {
			description: 'Array of Index of alignements inputs files.',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where bam will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(firstFile),subString,"")].',
			category: 'Output path/name option'
		}
		suffix: {
			description: 'Suffix to add for the output file (e.g sample.suffix.bam)[default: ".bqsr"]',
			category: 'Output path/name option'
		}
		refFasta: {
			description: 'Path to the reference file (format: fasta)',
			category: 'Required'
		}
		refFai: {
			description: 'Path to the reference file index (format: fai)',
			category: 'Required'
		}
		refDict: {
			description: 'Path to the reference file dict (format: dict)',
			category: 'Required'
		}
		intervalsPadding: {
			description: 'Amount of padding (in bp) to add to each interval you are including. [default: 0]',
			category: 'Tool option'
		}
		overlappingRule: {
			description: 'Interval merging rule for abutting intervals set to OVERLAPPING_ONLY [default: false => ALL]',
			category: 'Tool option'
		}
		intersectionRule: {
			description: 'Set merging approach to use for combining interval inputs to INTERSECTION [default: false => UNION]',
			category: 'Tool option'
		}
		bamIndex: {
			description: 'Create a BAM/CRAM index when writing a coordinate-sorted BAM/CRAM file [default: true]',
			category: 'Tool option'
		}
		bamMD5: {
			description: 'Create a MD5 digest for any BAM/SAM/CRAM file created [default: true]',
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

task collectMultipleMetrics {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-08-07"
	}

	input {
		String path_exe = "gatk"

		File in
		File bamIdx
		String? outputPath
		String? name
		String suffix = ".collectMultipleMetrics"

		File refFasta
		File refFai
		File refDict

		File? intervals

		Boolean collectAlignmentSummaryMetrics = true
		Boolean collectBaseDistributionByCycle = true
		Boolean collectInsertSizeMetrics = true
		Boolean meanQualityByCycle = true
		Boolean qualityScoreDistribution = true

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else sub(basename(in),"(.*)\.(sam|bam|cram)$","$1")
	String outputBase = if defined(outputPath) then "~{outputPath}/~{baseName}~{suffix}" else "~{baseName}~{suffix}"

	command <<<

		if [[ ! -d $(dirname ~{outputBase}) ]]; then
			mkdir -p $(dirname ~{outputBase})
		fi

		~{path_exe} CollectMultipleMetrics \
			--INPUT ~{in} \
			~{default="" "--INTERVALS " + intervals} \
			~{true="--PROGRAM CollectAlignmentSummaryMetrics" false="" collectAlignmentSummaryMetrics} \
			~{true="--PROGRAM CollectBaseDistributionByCycle" false="" collectBaseDistributionByCycle} \
			~{true="--PROGRAM CollectInsertSizeMetrics" false="" collectInsertSizeMetrics} \
			~{true="--PROGRAM MeanQualityByCycle" false="" meanQualityByCycle} \
			~{true="--PROGRAM QualityScoreDistribution" false="" qualityScoreDistribution} \
			--REFERENCE_SEQUENCE ~{refFasta} \
			--OUTPUT ~{outputBase}

	>>>

	output {
		File? outCollectAlignmentSummaryMetricsTxt = outputBase + ".alignment_summary_metrics"
		File? outCollectBaseDistributionByCycleTxt = outputBase + ".base_distribution_by_cycle_metrics"
		File? outCollectBaseDistributionByCyclePdf = outputBase + ".base_distribution_by_cycle.pdf"
		File? outCollectInsertSizeMetricsTxt = outputBase + ".insert_size_metrics"
		File? outCollectInsertSizeMetricsPdf = outputBase + ".insert_size_histogram.pdf"
		File? outMeanQualityByCycleTxt = outputBase + ".quality_by_cycle_metrics"
		File? outMeanQualityByCyclePdf = outputBase + ".quality_by_cycle.pdf"
		File? outQualityScoreDistributionTxt = outputBase + ".quality_distribution_metrics"
		File? outQualityScoreDistributionPdf = outputBase + ".quality_distribution.pdf"
		Array[File] collectMultipleMetrics = select_all([
			outCollectAlignmentSummaryMetricsTxt,
			outCollectBaseDistributionByCycleTxt,
			outCollectBaseDistributionByCyclePdf,
			outCollectInsertSizeMetricsTxt,
			outCollectInsertSizeMetricsPdf,
			outMeanQualityByCycleTxt,
			outMeanQualityByCyclePdf,
			outQualityScoreDistributionTxt,
			outQualityScoreDistributionPdf
		])
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'BAM to process.',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where bam will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(firstFile),subString,"")].',
			category: 'Output path/name option'
		}
		suffix: {
			description: 'Suffix to add for the output file (e.g sample.suffix.bam)[default: ".bqsr"]',
			category: 'Output path/name option'
		}
		refFasta: {
			description: 'Path to the reference file (format: fasta)',
			category: 'Required'
		}
		refFai: {
			description: 'Path to the reference file index (format: fai)',
			category: 'Required'
		}
		refDict: {
			description: 'Path to the reference file dict (format: dict)',
			category: 'Required'
		}
		collectAlignmentSummaryMetrics: {
			description: 'Use programm : CollectAlignmentSummaryMetrics [default: true]',
			category: 'Tool option'
		}
		collectBaseDistributionByCycle: {
			description: 'Use programm : CollectBaseDistributionByCycle [default: true]',
			category: 'Tool option'
		}
		collectInsertSizeMetrics: {
			description: 'Use programm : CollectInsertSizeMetrics [default: true]',
			category: 'Tool option'
		}
		meanQualityByCycle: {
			description: 'Use programm : MeanQualityByCycle [default: true]',
			category: 'Tool option'
		}
		qualityScoreDistribution: {
			description: 'Use programm : QualityScoreDistribution [default: true]',
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

task bedToIntervalList {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-08-10"
	}

	input {
		String path_exe = "gatk"

		File in
		File refDict
		String? outputPath
		String? name
		String ext = ".intervals"

		Boolean sort = true
		Boolean unique = false

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else sub(basename(in),"(.*)\.(bed)$","$1")
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{ext}" else "~{baseName}~{ext}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} BedToIntervalList \
			--INPUT ~{in} \
			--SEQUENCE_DICTIONARY ~{refDict} \
			~{true="--SORT" false="" sort} \
			~{true="--UNIQUE" false="" unique} \
			--OUTPUT ~{outputFile}

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
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'BED to convert into intervals list.',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where intervals list will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(in),"(.*)\.(bed)$","$1")].',
			category: 'Output path/name option'
		}
		ext: {
			description: 'Extension of the output file [default: ".intervals"]',
			category: 'Output path/name option'
		}
		refDict: {
			description: 'Path to the reference file dict (format: dict)',
			category: 'Required'
		}
		sort: {
			description: 'If true, sort the output interval list before writing it. [default: true]',
			category: 'Tool option'
		}
		unique: {
			description: 'If true, unique the output interval list by merging overlapping regions, before writing it (implies sort=true). [default: false]',
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

task intervalListToBed {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-08-19"
	}

	input {
		String path_exe = "gatk"

		File in
		String? outputPath
		String? name

		Boolean sort = true
		Int score = 500

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else sub(basename(in),".interval_list","")
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}.bed" else "~{baseName}.bed"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} IntervalListToBed \
			--INPUT ~{in} \
			~{true="--SORT" false="" sort} \
			--SCORE ~{score} \
			--OUTPUT ~{outputFile}

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
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'Intervals list to convert into BED.',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where BED will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(in),"(.*)\.(bed)$","$1")].',
			category: 'Output path/name option'
		}
		sort: {
			description: 'If true, sort the output interval list before writing it. [default: true]',
			category: 'Tool option'
		}
		score: {
			description: 'The score, between 0-1000, to output for each interval in the BED file. [default: 500]',
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

task haplotypeCaller {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.7"
		date: "2021-04-07"
	}

	input {
		String path_exe = "gatk"

		File in
		File idx
		String? outputPath
		String? name
		String subString = "\.(sam|bam|cram)$"
		String subStringReplace = ".haplotypeCaller.vcf"
		String subStringIntervals = "([0-9]+)-scattered.interval_list$"
		String subStringReplaceIntervals = ".$1"

		File refFasta
		File refFai
		File refDict

		## Annotation
		# File? alleles
		Boolean annotateNumAlleleDiscovered = false
		# Array[String]? annotations
		# Array[String]? annotationGroup
		# Array[String]? annotationExclude
		File? dbsnp
		File? dbsnpIdx

		## intervals
		File? intervals
		Int intervalsPadding = 0
		Boolean overlappingRule = false
		Boolean intersectionRule = false

		## filters
		Boolean useSoftClipped = false
		Int ploidy = 2
		Float standCallConf = 30.0
		# Int baseQuality = 18
		# Float conta = 0.0
		# Int minBaseQuality = 10
		# Int standCallConf = 30
		# Int maxAltAlleles = 6
		# Int maxGenotypeCount = 1024

		## assembly
		# Boolean graph = false
		# Boolean assembly = false
		# Int maxAssemblyRegionSize = 300
		# Int maxReadsPerStart = 50
		# Int minAssemblyRegionSize = 50

		## algo
		### heterozygosity
		# Float heterozygosity = 0.001
		# Float heterozygosityStd = 0.01
		# Float heterozygosityIndel = 0.000125
		### HMM
		# Int nativePairHMM = 4
		# Boolean useDoubleHMM = false
		# String implementationHMM = "FASTEST_AVAILABLE"
		### Other
		# Float activeProbThreshold = 0.002
		# Int alleleInfoReadsOverlapMergin = 2
		String smithAndWaterman = "FASTEST_AVAILABLE"
		String emitRefConfidence = "NONE"

		## output
		Boolean createVCFIdx = true
		Boolean createVCFMD5 = true

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseNameIntervals = if defined(intervals) then intervals else ""

	String getIntervalsBase = if defined(intervals) then sub(basename(baseNameIntervals),subStringIntervals,subStringReplaceIntervals) else ""

	String baseName = if defined(name) then name + getIntervalsBase + subStringReplace else sub(basename(in),subString,getIntervalsBase + subStringReplace)
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}" else "~{baseName}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} HaplotypeCaller \
			--input ~{in} \
			--reference ~{refFasta} \
			--sequence-dictionary ~{refDict} \
			--annotate-with-num-discovered-alleles ~{true="true" false="false" annotateNumAlleleDiscovered} \
			~{default="" "--dbsnp " + dbsnp} \
			~{default="" "--intervals " + intervals} \
			--interval-padding ~{intervalsPadding} \
			--interval-merging-rule ~{true="OVERLAPPING_ONLY" false="ALL" overlappingRule} \
			--interval-set-rule ~{true="INTERSECTION" false="UNION" intersectionRule} \
			--dont-use-soft-clipped-bases ~{true="false" false="true" useSoftClipped} \
			--sample-ploidy ~{ploidy} \
			--standard-min-confidence-threshold-for-calling ~{standCallConf} \
			--smith-waterman ~{smithAndWaterman} \
			--emit-ref-confidence ~{emitRefConfidence} \
			~{true="--create-output-variant-index" false="" createVCFIdx} \
			~{true="--create-output-variant-md5" false="" createVCFMD5} \
			--output ~{outputFile}

	>>>

	output {
		File outputFile = outputFile
		File? outputFileIdx = outputFile + ".idx"
		File? outputFileMD5 = outputFile + ".md5"
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'BAM file.',
			category: 'Required'
		}
		idx: {
			description: 'Index of the BAM file.',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where files will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file name [default: base on the input file].',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Substring to replace (e.g. remove extension) [default: "\.(sam|bam|cram)$"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'Substring used to replace (e.g. add a suffix) [default: ".haplotypeCaller.vcf"]',
			category: 'Output path/name option'
		}
		subStringIntervals: {
			description: 'Substring to replace for interval file (e.g. remove extension) [default: "([0-9]+)-scattered.interval_list$"]',
			category: 'Output path/name option'
		}
		subStringReplaceIntervals: {
			description: 'Substring used to replace for interval file (e.g. add a suffix) [default: ".$1"]',
			category: 'Output path/name option'
		}
		refFasta: {
			description: 'Path to the reference file (format: fasta)',
			category: 'Required'
		}
		refFai: {
			description: 'Path to the reference file index (format: fai)',
			category: 'Required'
		}
		refDict: {
			description: 'Path to the reference file dict (format: dict)',
			category: 'Required'
		}
		annotateNumAlleleDiscovered: {
			description: 'If provided, we will annotate records with the number of alternate alleles that were discovered (but not necessarily genotyped) at a given site [default: false]',
			category: 'Option: Annotation'
		}
		dbsnp: {
			description: 'Path to the file containing dbsnp (format: vcf)',
			category: 'Option: Annotation'
		}
		dbsnpIdx: {
			description: 'Path to the index of dbsnp file (format: tbi)',
			category: 'Option: Annotation'
		}
		intervals: {
			description: 'Path to a file containing genomic intervals over which to operate. (format intervals list: chr1:1000-2000)',
			category: 'Option: Intervals'
		}
		intervalsPadding: {
			description: 'Amount of padding (in bp) to add to each interval you are including. [default: 0]',
			category: 'Option: Intervals'
		}
		overlappingRule: {
			description: 'Interval merging rule for abutting intervals set to OVERLAPPING_ONLY [default: false => ALL]',
			category: 'Option: Intervals'
		}
		intersectionRule: {
			description: 'Set merging approach to use for combining interval inputs to INTERSECTION [default: false => UNION]',
			category: 'Option: Intervals'
		}
		useSoftClipped: {
			description: 'Analyze soft clipped bases in the reads [default: false]',
			category: 'Option: filters'
		}
		ploidy: {
			description: 'Ploidy (number of chromosomes) per sample. [default: 2]',
			category: 'Option: filters'
		}
		standCallConf: {
			description: 'The minimum phred-scaled confidence threshold at which variants should be called [default: 30.0]',
			category: 'Option: filters'
		}
		smithAndWaterman: {
			description: 'Which Smith-Waterman implementation to use, generally FASTEST_AVAILABLE is the right choice (possible values: FASTEST_AVAILABLE, AVX_ENABLED, JAVA) [default: FASTEST_AVAILABLE]',
			category: 'Option: Algo'
		}
		emitRefConfidence: {
			description: 'Mode for emitting reference confidence scores (possible values: NONE, BP_RESOLUTION, GVCF) [default: None]',
			category: 'Option: Algo'
		}
		createVCFIdx: {
			description: 'If true, create a VCF index when writing a coordinate-sorted VCF file. [Default: true]',
			category: 'Option: output'
		}
		createVCFMD5: {
			description: 'If true, create a a MD5 digest any VCF file created. [Default: true]',
			category: 'Option: output'
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

task haplotypeCallerMultiple {
	meta {
		author: "Olivier ARDOUIN"
		email: "o-ardouin(at)chu-montpellier.fr"
		version: "0.0.7"
		date: "2021-10-11"
	}

	input {
		String path_exe = "gatk"

		Array[File] in
		Array[File] idx
		String? outputPath
		String? name
		String subString = "\.(sam|bam|cram)$"
		String subStringReplace = ".haplotypeCaller.vcf"
		String subStringIntervals = "([0-9]+)-scattered.interval_list$"
		String subStringReplaceIntervals = ".$1"

		File refFasta
		File refFai
		File refDict

		## Annotation
		Boolean annotateNumAlleleDiscovered = false
		File? dbsnp
		File? dbsnpIdx

		## intervals
		File? intervals
		Int intervalsPadding = 0
		Boolean overlappingRule = false
		Boolean intersectionRule = false

		## filters
		Boolean useSoftClipped = false
		Int ploidy = 2
		Float standCallConf = 30.0

		String smithAndWaterman = "FASTEST_AVAILABLE"
		String emitRefConfidence = "NONE"

		## output
		Boolean createVCFIdx = true
		Boolean createVCFMD5 = true

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseNameIntervals = if defined(intervals) then intervals else ""

	String getIntervalsBase = if defined(intervals) then sub(basename(baseNameIntervals),subStringIntervals,subStringReplaceIntervals) else ""

	String baseName = if defined(name) then name + getIntervalsBase + subStringReplace else sub(basename(in[0]),subString,getIntervalsBase + subStringReplace)
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}" else "~{baseName}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} HaplotypeCaller \
			--input ~{sep=' --input  ' in} \
			--reference ~{refFasta} \
			--sequence-dictionary ~{refDict} \
			--annotate-with-num-discovered-alleles ~{true="true" false="false" annotateNumAlleleDiscovered} \
			~{default="" "--dbsnp " + dbsnp} \
			~{default="" "--intervals " + intervals} \
			--interval-padding ~{intervalsPadding} \
			--interval-merging-rule ~{true="OVERLAPPING_ONLY" false="ALL" overlappingRule} \
			--interval-set-rule ~{true="INTERSECTION" false="UNION" intersectionRule} \
			--dont-use-soft-clipped-bases ~{true="false" false="true" useSoftClipped} \
			--sample-ploidy ~{ploidy} \
			--standard-min-confidence-threshold-for-calling ~{standCallConf} \
			--smith-waterman ~{smithAndWaterman} \
			--emit-ref-confidence ~{emitRefConfidence} \
			~{true="--create-output-variant-index" false="" createVCFIdx} \
			~{true="--create-output-variant-md5" false="" createVCFMD5} \
			--output ~{outputFile}

	>>>

	output {
		File outputFile = outputFile
		File? outputFileIdx = outputFile + ".idx"
		File? outputFileMD5 = outputFile + ".md5"
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'BAM file.',
			category: 'Required'
		}
		idx: {
			description: 'Index of the BAM file.',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where files will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file name [default: base on the input file].',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Substring to replace (e.g. remove extension) [default: "\.(sam|bam|cram)$"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'Substring used to replace (e.g. add a suffix) [default: ".haplotypeCaller.vcf"]',
			category: 'Output path/name option'
		}
		subStringIntervals: {
			description: 'Substring to replace for interval file (e.g. remove extension) [default: "([0-9]+)-scattered.interval_list$"]',
			category: 'Output path/name option'
		}
		subStringReplaceIntervals: {
			description: 'Substring used to replace for interval file (e.g. add a suffix) [default: ".$1"]',
			category: 'Output path/name option'
		}
		refFasta: {
			description: 'Path to the reference file (format: fasta)',
			category: 'Required'
		}
		refFai: {
			description: 'Path to the reference file index (format: fai)',
			category: 'Required'
		}
		refDict: {
			description: 'Path to the reference file dict (format: dict)',
			category: 'Required'
		}
		annotateNumAlleleDiscovered: {
			description: 'If provided, we will annotate records with the number of alternate alleles that were discovered (but not necessarily genotyped) at a given site [default: false]',
			category: 'Option: Annotation'
		}
		dbsnp: {
			description: 'Path to the file containing dbsnp (format: vcf)',
			category: 'Option: Annotation'
		}
		dbsnpIdx: {
			description: 'Path to the index of dbsnp file (format: tbi)',
			category: 'Option: Annotation'
		}
		intervals: {
			description: 'Path to a file containing genomic intervals over which to operate. (format intervals list: chr1:1000-2000)',
			category: 'Option: Intervals'
		}
		intervalsPadding: {
			description: 'Amount of padding (in bp) to add to each interval you are including. [default: 0]',
			category: 'Option: Intervals'
		}
		overlappingRule: {
			description: 'Interval merging rule for abutting intervals set to OVERLAPPING_ONLY [default: false => ALL]',
			category: 'Option: Intervals'
		}
		intersectionRule: {
			description: 'Set merging approach to use for combining interval inputs to INTERSECTION [default: false => UNION]',
			category: 'Option: Intervals'
		}
		useSoftClipped: {
			description: 'Analyze soft clipped bases in the reads [default: false]',
			category: 'Option: filters'
		}
		ploidy: {
			description: 'Ploidy (number of chromosomes) per sample. [default: 2]',
			category: 'Option: filters'
		}
		standCallConf: {
			description: 'The minimum phred-scaled confidence threshold at which variants should be called [default: 30.0]',
			category: 'Option: filters'
		}
		smithAndWaterman: {
			description: 'Which Smith-Waterman implementation to use, generally FASTEST_AVAILABLE is the right choice (possible values: FASTEST_AVAILABLE, AVX_ENABLED, JAVA) [default: FASTEST_AVAILABLE]',
			category: 'Option: Algo'
		}
		emitRefConfidence: {
			description: 'Mode for emitting reference confidence scores (possible values: NONE, BP_RESOLUTION, GVCF) [default: None]',
			category: 'Option: Algo'
		}
		createVCFIdx: {
			description: 'If true, create a VCF index when writing a coordinate-sorted VCF file. [Default: true]',
			category: 'Option: output'
		}
		createVCFMD5: {
			description: 'If true, create a a MD5 digest any VCF file created. [Default: true]',
			category: 'Option: output'
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

task gatherVcfFiles {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.3"
		date: "2020-12-17"
	}

	input {
		String path_exe = "gatk"

		Array[File]+ in
		String? outputPath
		String? name ### Warning if name defined and not suffixed by .vcf ou .vcf.gz ... it will crash
		String subString = "(\.[0-9]+)?(\.[a-zA-Z_-]+)?\.(vcf)$"
		String subStringReplace = "$2.gather.vcf"

		Boolean reorder = true

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String firstFile = basename(in[0])
	String baseName = if defined(name) then name else sub(basename(firstFile),subString,subStringReplace)
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}" else "~{baseName}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} GatherVcfs \
			--INPUT ~{sep=" --INPUT " in} \
			~{true="--REORDER_INPUT_BY_FIRST_VARIANT" false="" reorder} \
			--OUTPUT ~{outputFile}

	>>>

	output {
		File outputFile = outputFile
		File outputFileIdx = outputFile + ".idx"
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'Array of VCFs to gather.',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where vcf will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(firstFile),subString,"")].',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Substring to replace (e.g. remove extension) [default: "(\.[0-9]+)?(\.[a-zA-Z_-]+)?\.(vcf)$"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'Substring used to replace (e.g. add a suffix) [default: "$2.gather.vcf"]',
			category: 'Output path/name option'
		}
		reorder: {
			description: 'If true the program will reorder INPUT according to the genomic location of the first variant in each file. [Default: true]',
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

task splitVcfs {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.2"
		date: "2020-12-17"
	}

	input {
		String path_exe = "gatk"

		File in
		String? outputPath
		String? name
		String subString = "\.(vcf|bcf|vcf\.gz)$"
		String subStringReplace = ".split"
		String? ext

		File? refDict
		Boolean strict = true

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String extOut = if defined(ext) then ext else sub(basename(in),"(.*\.)(vcf|bcf|vcf\.gz)$","$2")
	String extIdx = if sub(basename(in),"(.*\.)(.gz)$","$2")== ".gz" then ".tbi" else ".idx"
	String baseName = if defined(name) then name else sub(basename(in),subString,subStringReplace)
	String outputFileBase = if defined(outputPath) then "~{outputPath}/~{baseName}" else "~{baseName}"

	command <<<

		if [[ ! -d $(dirname ~{outputFileBase}) ]]; then
			mkdir -p $(dirname ~{outputFileBase})
		fi

		~{path_exe} SplitVcfs \
			~{true="--STRICT" false="" strict} \
			~{default="" "--SEQUENCE_DICTIONARY " + refDict} \
			--INPUT ~{in} \
			--INDEL_OUTPUT ~{outputFileBase + ".indels"}~{"." + extOut} \
			--SNP_OUTPUT ~{outputFileBase + ".snps"}~{"." + extOut}

	>>>

	output {
		File outputFileSnp = outputFileBase + ".snps." + extOut
		File outputFileSnpIdx = outputFileBase + ".snps." + extOut + extIdx
		File outputFileIndel = outputFileBase + ".indels." + extOut
		File outputFileIndelIdx = outputFileBase + ".indels." + extOut + extIdx
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'VCF to split.',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where vcf will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(firstFile),subString,"")].',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'subString to replace [default: ".split"]',
			category: 'Output path/name option'
		}
		ext: {
			description: 'Extension of the output file (".vcf" or ".bcf") [default: same as input]',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Extension to remove from the input file [default: "(\.[0-9]+)?\.vcf$"]',
			category: 'Output path/name option'
		}
		refDict: {
			description: 'Path to the reference file dict (format: dict)',
			category: 'Tool option'
		}
		strict: {
			description: 'If true an exception will be thrown if an event type other than SNP or indel is encountered [default: true]',
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

task variantFiltration {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.6"
		date: "2021-04-07"
	}

	input {
		String path_exe = "gatk"

		File in
		File? inIdx
		String? outputPath
		String? name
		String subString = "\.(vcf|bcf|vcf\.gz)$"
		String subStringReplace = ".filter.vcf"

		File refFasta
		File refFai
		File refDict

		Int clusterSize = 3
		Int clusterWindow = 0

		Float? LowQualByDepth
		Float? FSStrandBias
		Float? LowReadPosRankSum
		Float? SORStrandBias
		Float? HomopolymerRegion
		Float? LowCoverage
		Float? LowMappingQuality
		Float? LowMappingQualityRankSum

		Boolean createVCFMD5 = true

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name + subStringReplace else sub(basename(in),subString,subStringReplace)
	String extIdx = if sub(baseName,"(.*\.)(.gz)$","$2") == ".gz" then ".tbi" else ".idx"
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}" else "~{baseName}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} VariantFiltration \
			~{default="" "--sequence-dictionary " + refDict} \
			--cluster-size ~{clusterSize} \
			--cluster-window-size ~{clusterWindow} \
			~{default="" "--filter-name \"LowQualByDepth\" --filter-expression \"QD < " + LowQualByDepth}~{true="\"" false="" defined(LowQualByDepth)} \
			~{default="" "--filter-name \"FSStrandBias\" --filter-expression \"FS > " + FSStrandBias}~{true="\"" false="" defined(FSStrandBias)} \
			~{default="" "--filter-name \"LowMappingQuality\" --filter-expression \"MQ < " + LowMappingQuality}~{true="\"" false="" defined(LowMappingQuality)} \
			~{default="" "--filter-name \"LowMappingQualityRankSum\" --filter-expression \"MQRankSum < " + LowMappingQualityRankSum}~{true="\"" false="" defined(LowMappingQualityRankSum)} \
			~{default="" "--filter-name \"LowReadPosRankSum\" --filter-expression \"ReadPosRankSum < " + LowReadPosRankSum}~{true="\"" false="" defined(LowReadPosRankSum)} \
			~{default="" "--filter-name \"SORStrandBias\" --filter-expression \"SOR > " + SORStrandBias}~{true="\"" false="" defined(SORStrandBias)} \
			~{default="" "--filter-name \"HomopolymerRegion\" --filter-expression \"POLYX > " + HomopolymerRegion}~{true="\"" false="" defined(HomopolymerRegion)} \
			~{default="" "--filter-name \"LowCoverage\" --filter-expression \"DP < " + LowCoverage}~{true="\"" false="" defined(LowCoverage)} \
			--create-output-variant-index \
			~{true="--create-output-variant-md5" false="" createVCFMD5} \
			--variant ~{in} \
			--output ~{outputFile}

	>>>

	output {
		File outputFile = outputFile
		File outputFileIdx = outputFile + extIdx
		File? outputFileMD5 = outputFile + ".md5"
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'VCF to filter.',
			category: 'Required'
		}
		in: {
			description: 'VCF index.',
			category: 'Optional'
		}
		outputPath: {
			description: 'Output path where vcf will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(firstFile),subString,"")].',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Extension to remove from the input file [default: "(\.[0-9]+)?\.vcf$"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'subString to replace [default: ".filter"]',
			category: 'Output path/name option'
		}
		refFasta: {
			description: 'Path to the reference file (format: fasta)',
			category: 'Required'
		}
		refFai: {
			description: 'Path to the reference file index (format: fai)',
			category: 'Required'
		}
		refDict: {
			description: 'Path to the reference file dict (format: dict)',
			category: 'Required'
		}
		clusterSize: {
			description: 'The number of SNPs which make up a cluster. Must be at least 2 [Default: 3]',
			category: 'Option: cluster'
		}
		clusterWindow: {
			description: 'The window size (in bases) in which to evaluate clustered SNPs [Default: 0]',
			category: 'Option: cluster'
		}
		LowQualByDepth: {
			description: 'Threshold below which QD the variant will be tagged as LowQualByDepth',
			category: 'Option: filter (predefined)'
		}
		FSStrandBias: {
			description: 'Threshold above which FS the variant will be tagged as FSStrandBias',
			category: 'Option: filter (predefined)'
		}
		LowMappingQuality: {
			description: 'Threshold below which MQ the variant will be tagged as LowMappingQuality',
			category: 'Option: filter (predefined)'
		}
		LowMappingQualityRankSum: {
			description: 'Threshold below which MQRankSum the variant will be tagged as LowMappingQualityRankSum',
			category: 'Option: filter (predefined)'
		}
		LowReadPosRankSum: {
			description: 'Threshold below which ReadPosRankSum the variant will be tagged as LowReadPosRankSum',
			category: 'Option: filter (predefined)'
		}
		SORStrandBias: {
			description: 'Threshold above which SOR the variant will be tagged as SORStrandBias',
			category: 'Option: filter (predefined)'
		}
		HomopolymerRegion: {
			description: 'Threshold above which POLYX the variant will be tagged as HomopolymerRegion',
			category: 'Option: filter (predefined)'
		}
		LowCoverage: {
			description: 'Threshold below which DP the variant will be tagged as LowCoverage',
			category: 'Option: filter (predefined)'
		}
		createVCFMD5: {
			description: 'If true, create a a MD5 digest any VCF file created. [Default: true]',
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

task mergeVcfs {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-08-26"
	}

	input {
		String path_exe = "gatk"

		Array[File]+ in
		String? outputPath
		String? name
		String subString = "\.(vcf|bcf)$"
		String subStringReplace = ""
		String suffix = ".merge"
		String ext = ".vcf"

		File? refDict

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String firstFile = basename(in[0])

	String extOut = if defined(ext) then ext else sub(basename(firstFile),"(.*)(\.vcf|\.bcf)$","$2")
	String baseName = if defined(name) then name else sub(basename(firstFile),subString,subStringReplace)
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{suffix}~{extOut}" else "~{baseName}~{suffix}~{extOut}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} MergeVcfs \
			~{default="" "--SEQUENCE_DICTIONARY " + refDict} \
			--INPUT ~{sep=" --INPUT " in} \
			--OUTPUT ~{outputFile}

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
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'List of VCFs files',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where merged vcf will be written.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(firstFile),subString,"")].',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Extension to remove from the input file [default: "\.(vcf|bcf)$"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'subString replace by this string [default: ""]',
			category: 'Output path/name option'
		}
		suffix: {
			description: 'Suffix to add for the output file (e.g sample.suffix.bam)[default: ".merge"]',
			category: 'Output path/name option'
		}
		ext: {
			description: 'Extension for the output file [default: ".recal"]',
			category: 'Output path/name option'
		}
		refDict: {
			description: 'Path to the reference file dict (format: dict)',
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

task sortVcf {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-08-27"
	}

	input {
		String path_exe = "gatk"

		File in
		String? outputPath
		String? name
		String subString = "\.(vcf|bcf)$"
		String suffix = ".sort"
		String ext = ".vcf"

		File? refDict

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String extOut = if defined(ext) then ext else sub(basename(in),"(.*)(\.vcf|\.bcf)$","$2")
	String baseName = if defined(name) then name else sub(basename(in),subString,"")
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{suffix}~{extOut}" else "~{baseName}~{suffix}~{extOut}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} SortVcf \
			~{default="" "--SEQUENCE_DICTIONARY " + refDict} \
			--INPUT ~{sep=" --INPUT " in} \
			--OUTPUT ~{outputFile}

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
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'List of VCFs files',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where sorted vcf will be written.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(in),subString,"")].',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Extension to remove from the input file [default: "\.(vcf|bcf)$"]',
			category: 'Output path/name option'
		}
		suffix: {
			description: 'Suffix to add for the output file (e.g sample.suffix.bam)[default: ".sort"]',
			category: 'Output path/name option'
		}
		ext: {
			description: 'Extension for the output file [default: ".recal"]',
			category: 'Output path/name option'
		}
		refDict: {
			description: 'Path to the reference file dict (format: dict)',
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

task splitNCigarReads {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.2"
		date: "2021-04-07"
	}

	input {
		String path_exe = "gatk"

		File in
		String? outputPath
		String? name
		String subString = "(\.sam|\.bam|\.cram)$"
		String subStringReplace = ".spliNcigar.bam"

		File refFasta
		File refFai
		File refDict

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

		~{path_exe} SplitNCigarReads \
			--reference ~{refFasta} \
			--input ~{in} \
			--output ~{outputFile}

	>>>

	output {
		File outputBam = outputFile
		File outputIdx = sub(outputFile,"m$", "i")
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'Input file bam.',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where sorted vcf will be written.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(in),subString,"")].',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Extension to remove from the input file [default: "(\.sam|\.bam|\.cram)$"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'subString replace by this string [default: ".spliNcigar.bam"]',
			category: 'Output path/name option'
		}
		refFasta: {
			description: 'Path to the reference file (format: fasta)',
			category: 'Required'
		}
		refFai: {
			description: 'Path to the reference file index (format: fai)',
			category: 'Required'
		}
		refDict: {
			description: 'Path to the reference file dict (format: dict)',
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

task revertSam {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2021-03-30"
	}

	input {
		String path_exe = "gatk"

		File in
		String? outputPath
		String? name
		String subString = "(\.sam|\.bam|\.cram)$"
		String subStringReplace = ".revertSam.bam"

		String validationStringency = "SILENT"

		String sortOrder = "queryname"
		Array[String] attrToClear = ["NM", "UQ", "PG", "MD", "MQ", "SA", "MC", "AS"]

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
	String baseNameTSV = sub(baseName,"\.(bam|sam|cram)",".tsv")
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}" else "~{baseName}"
	String outputFileTSV = if defined(outputPath) then "~{outputPath}/~{baseNameTSV}" else "~{baseNameTSV}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} RevertSam \
			--VALIDATION_STRINGENCY ~{validationStringency} \
			--ATTRIBUTE_TO_CLEAR ~{sep="--ATTRIBUTE_TO_CLEAR " attrToClear} \
			--SORT_ORDER ~{sortOrder} \
			--INPUT ~{in} \
			--OUTPUT ~{outputFile} \
			--OUTPUT_MAP ~{outputFileTSV}

	>>>

	output {
		File outputFile = outputFile
		File outputFileTSV = outputFileTSV
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'Input file bam.',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where bam/sam will be written.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(in),subString,"")].',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Extension to remove from the input file [default: "(\.sam|\.bam|\.cram)$"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'subString replace by this string [default: ".spliNcigar.bam"]',
			category: 'Output path/name option'
		}
		validationStringency: {
			description: 'Validation stringency for all SAM files read by this program. Setting stringency to SILENT can improve performance when processing a BAM file in which variable-length data (read, qualities, tags) do not otherwise need to be decoded. [Default: "SILENT"]',
			category: 'Option: GATK common'
		}
		attrToClear: {
			description: 'When removing alignment information, the set of optional tags to remove. [Default: ["NM", "UQ", "PG", "MD", "MQ", "SA", "MC", "AS"]]',
			category: 'Option: filter'
		}
		sortOrder: {
			description: 'The sort order to create the reverted output file with. [Default: "queryname"] Possible values: {unsorted, queryname, coordinate, duplicate, unknown}',
			category: 'Option: filter'
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

task samToFastq {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2021-03-31"
	}

	input {
		String path_exe = "gatk"

		File in
		String? outputPath
		String? name
		String subString = "(\.sam|\.bam|\.cram)$"
		String subStringReplace = ".fastq.gz"

		Boolean paired = true

		String validationStringency = "SILENT"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String subStringReplaceR1 = if (paired) then "_R1~{subStringReplace}" else subStringReplace
	String baseNameR1 = if defined(name) then name + subStringReplaceR1 else sub(basename(in),subString,subStringReplaceR1)
	String outputFileR1 = if defined(outputPath) then "~{outputPath}/~{baseNameR1}" else "~{baseNameR1}"

	String subStringReplaceR2 = if (paired) then "_R2~{subStringReplace}" else subStringReplace
	String baseNameR2 = if defined(name) then name + subStringReplaceR2 else sub(basename(in),subString,subStringReplaceR2)
	String? outputFileR2 = if (paired) then if defined(outputPath) then "~{outputPath}/~{baseNameR2}" else "~{baseNameR2}" else ""

	command <<<

		if [[ ! -d $(dirname ~{outputFileR1}) ]]; then
			mkdir -p $(dirname ~{outputFileR1})
		fi

		~{path_exe} SamToFastq \
			--VALIDATION_STRINGENCY ~{validationStringency} \
			--INPUT ~{in} \
			--FASTQ ~{outputFileR1} \
			~{true="--SECOND_END_FASTQ " false="" paired}~{outputFileR2}

	>>>

	output {
		File fastqR1 = outputFileR1
		File? fastqR2 = outputFileR2
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'Input file bam.',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where fastqs will be written.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(in),subString,"")].',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Extension to remove from the input file [default: "(\.sam|\.bam|\.cram)$"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'subString replace by this string [default: ".spliNcigar.bam"]',
			category: 'Output path/name option'
		}
		validationStringency: {
			description: 'Validation stringency for all SAM files read by this program. Setting stringency to SILENT can improve performance when processing a BAM file in which variable-length data (read, qualities, tags) do not otherwise need to be decoded. [Default: "SILENT"]',
			category: 'Option: GATK common'
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

task markDuplicates {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2021-03-31"
	}

	input {
		String path_exe = "gatk"

		File in
		String? outputPath
		String? name
		String subString = "(\.sam|\.bam|\.cram)$"
		String subStringReplace = ".markduplicates.bam"

		Boolean createIndex = true
		String validationStringency = "SILENT"

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
	String baseNameMetrics = sub(baseName,"\.(bam|sam|cram)",".metrics.txt")
	String baseNameIndex = sub(baseName,"m$","i")
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}" else "~{baseName}"
	String outputFileMetrics = if defined(outputPath) then "~{outputPath}/~{baseNameMetrics}" else "~{baseNameMetrics}"
	String outputFileIndex = if defined(outputPath) then "~{outputPath}/~{baseNameIndex}" else "~{baseNameIndex}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} MarkDuplicates \
			--VALIDATION_STRINGENCY ~{validationStringency} \
			--CREATE_INDEX ~{createIndex} \
			--INPUT ~{in} \
			--OUTPUT ~{outputFile} \
			--METRICS_FILE ~{outputFileMetrics}

	>>>

	output {
		File outputFile = outputFile
		File outputFileMetrics = outputFileMetrics
		File? outputFileIndex = outputFileIndex
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'Input file bam.',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where sorted bam/sam will be written.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(in),subString,"")].',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Extension to remove from the input file [default: "(\.sam|\.bam|\.cram)$"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'subString replace by this string [default: ".spliNcigar.bam"]',
			category: 'Output path/name option'
		}
		validationStringency: {
			description: 'Validation stringency for all SAM files read by this program. Setting stringency to SILENT can improve performance when processing a BAM file in which variable-length data (read, qualities, tags) do not otherwise need to be decoded. [Default: "SILENT"]',
			category: 'Option: GATK common'
		}
		createIndex: {
			description: 'Whether to create a BAM index when writing a coordinate-sorted BAM file. [Default: true]',
			category: 'Option: GATK common'
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

task CollectInsertSizeMetrics {
	meta {
		author: "Olivier Ardouin"
		email: "o-ardouin(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-10-11"
	}

	input {
		String path_exe = "gatk"

		File in
		Float MinPct = 0.5
		String? outputPath
		String? name
		String suffix = ".InsertSizeMetrics"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else sub(basename(in),"(.*)\.(sam|bam|cram)$","$1")
	String outputBase = if defined(outputPath) then "~{outputPath}/~{baseName}~{suffix}" else "~{baseName}~{suffix}"
	String outputHistogram = if defined(outputPath) then "~{outputPath}/~{baseName}~{suffix}.pdf" else "~{baseName}~{suffix}.pdf"

	command <<<

		if [[ ! -d $(dirname ~{outputBase}) ]]; then
			mkdir -p $(dirname ~{outputBase})
		fi

		~{path_exe} CollectInsertSizeMetrics \
			--INPUT ~{in} \
			--Histogram_FILE ~{outputHistogram} \
			--OUTPUT ~{outputBase} \
			--MINIMUM_PCT ~{MinPct}

	>>>

	output {
		File insertSizeMetrics = "~{outputBase}"
		File insertSizeMetricsHistogram = "~{outputHistogram}"
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'BAM to process.',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where bam will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(firstFile),subString,"")].',
			category: 'Output path/name option'
		}
		suffix: {
			description: 'Suffix to add for the output file (e.g sample.suffix.bam)[default: ".InsertSizeMetrics"]',
			category: 'Option'
		}
		MinPct : {
			description: 'When generating the Histogram, discard any data categories (out of FR, TANDEM, RF) that have fewer than this percentage of overall reads. (Float; Range: 0 to 1). [default: 0.5]'
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

task CollectHsMetrics {
	meta {
		author: "Olivier Ardouin"
		email: "o-ardouin(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-10-14"
	}

	input {
		String path_exe = "gatk"

		File in
		String? outputPath
		String? name
		String suffix = ".HSMetrics.txt"

		File refFasta
		File refFai
		File targetIntervalList
		File? baitIntervalList

		Int CoverageCap = 1000

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	File baitList = if defined(baitIntervalList) then baitIntervalList else targetIntervalList

	String baseName = if defined(name) then name else sub(basename(in),"(.*)\.(sam|bam|cram)$","$1")
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{suffix}" else "~{baseName}~{suffix}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} CollectHsMetrics \
			--INPUT ~{in} \
			--REFERENCE_SEQUENCE ~{refFasta} \
			--TARGET_INTERVALS ~{targetIntervalList} \
			--BAIT_INTERVALS ~{baitList} \
			--OUTPUT ~{outputFile} \
			--COVERAGE_CAP ~{CoverageCap}

	>>>

	output {
		File HSMetrics = "~{outputFile}"
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		in: {
			description: 'BAM to process.',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where metrics will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(firstFile),subString,"")].',
			category: 'Output path/name option'
		}
		suffix: {
			description: 'Suffix to add for the output file (e.g sample.suffix.bam)[default: ".HSMetrics.txt"]',
			category: 'Option'
		}
		refFasta: {
			description: 'Fasta reference file',
			category: 'Required'
		}
		targetIntervalList: {
			description: 'target IntervalList file',
			category: 'Required'
		}
		baitIntervalList: {
			description: 'bait IntervalList file [default = targetIntervalList]',
			category: 'Optional'
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
