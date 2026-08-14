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

task splitIntervals {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.1.2"
		date: "2026-08-12"
	}

	input {
		String path_exe = "gatk"

		File bed
		String outputPath
		String subdir = ""
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
	String outputRep = "~{outputPath}/~{subdir}/~{baseName}"

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
		bind_opt: "~{outputPath}/~{subdir}" + "," + "~{refFasta}" + "," + "~{bed}"
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
		subdir: {
			description: 'Subdirectory where to write output. [default: ""]',
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
		version: "0.1.2"
		date: "2026-08-12"
	}

	input {
		String path_exe = "gatk"

		File bam
		File bai = bam + ".bai"
		String outputPath
		String subdir = ""
		String? name
		File? bed
		String subString_intervals = "([0-9]+)-scattered.interval_list"
		String subStringReplace_intervals = "$1"
		String ext = ".recal"

		Array[File]+ knownSites
		Array[File]+ knownSitesIdx

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
	String outputFile = "~{outputPath}/~{subdir}/~{baseName}.~{baseIntervals}~{ext}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} BaseRecalibrator \
			--input "~{bam}" \
			--reference "~{refFasta}" \
			~{default="" "--intervals " + bed} \
			--known-sites ~{sep=" --known-sites " knownSites} \
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
		bind_opt: "~{outputPath}/~{subdir}" + "," + "~{bam}" + "," + "~{baseNameIntervals}" + "," + "~{refFasta}" + "~{default='' ',' + bed}" + "," + "~{sep=',' knownSites}"
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
		subdir: {
			description: 'Subdirectory where to write output. [default: ""]',
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
		version: "0.1.1"
		date: "2026-08-12"
	}

	input {
		String path_exe = "gatk"

		Array[File]+ reports
		String outputPath
		String subdir = ""
		String? name
		String subString = "(\.[0-9]+)?\.recal$"
		String subStringReplace = ""
		String ext = ".bqsr.report"

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

	String firstFile = basename(reports[0])
	String baseName = if defined(name) then name else sub(basename(firstFile),subString,subStringReplace)
	String outputFile = "~{outputPath}/~{subdir}/~{baseName}~{ext}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} GatherBQSRReports \
			--input "~{sep='" --input "' reports}" \
			--output "~{outputFile}"

	>>>

	output {
		File report = outputFile
	}

	runtime {
		bind_opt: "~{outputPath}/~{subdir}" + "," + "~{sep=',' reports}"
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
		docker: "~{apptainer_img}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gatk"]',
			category: 'System'
		}
		reports: {
			description: 'List of scattered BQSR report files',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where bqsr report will be generated.',
			category: 'Output path/name option'
		}
		subdir: {
			description: 'Subdirectory where to write output. [default: ""]',
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
		apptainer_img: {
			description: 'Sets the apptainer image you want to use [default: gatk4:4.6.2.0]',
			category: 'System'
		}
	}
}

task applyBQSR {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.1.1"
		date: "2026-08-12"
	}

	input {
		String path_exe = "gatk"

		File bam
		File bamIdx = bam + ".bai"
		File bqsrReport
		File? intervals
		String subString_intervals = "([0-9]+)-scattered.interval_list"
		String subStringReplace_intervals = "$1"
		String outputPath
		String subdir = ""
		String? name
		String suffix = ".bqsr"

		File refFasta
		File refFai = refFasta + ".fai"
		File refDict = sub(refFasta, "(.*).(fa|fasta)", "$1.dict")

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
		String apptainer_img = "gatk4:4.6.2.0"
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseNameIntervals = if defined(intervals) then intervals else ""
	String baseIntervals = if defined(intervals) then "." + sub(basename(baseNameIntervals),subString_intervals,subStringReplace_intervals) else ""

	String baseName = if defined(name) then name else sub(basename(bam),"(.*)\.(sam|bam|cram)$","$1")
	String ext = sub(basename(bam),"(.*)\.(sam|bam|cram)$","$2")
	String outputBamFile = "~{outputPath}/~{subdir}/~{baseName}~{suffix}~{baseIntervals}\.~{ext}"
	String outputBaiFile = sub(outputBamFile,"(m)$","i")

	command <<<

		if [[ ! -d $(dirname ~{outputBamFile}) ]]; then
			mkdir -p $(dirname ~{outputBamFile})
		fi

		~{path_exe} ApplyBQSR \
			--input "~{bam}" \
			--bqsr-recal-file "~{bqsrReport}" \
			--reference "~{refFasta}" \
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
			--output "~{outputBamFile}"

	>>>

	output {
		File outputBam = outputBamFile
		File outputBai = outputBaiFile
	}

	runtime {
		bind_opt: "~{outputPath}/~{subdir}" + "," + "~{bam}" + "," + "~{baseNameIntervals}" + "," + "~{refFasta}" + "," + "~{bqsrReport}" + "~{default='' ',' + intervals}"
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
		subdir: {
			description: 'Subdirectory where to write output. [default: ""]',
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
		apptainer_img: {
			description: 'Sets the apptainer image you want to use [default: gatk4:4.6.2.0]',
			category: 'System'
		}
	}
}

task leftAlignIndels {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.1.1"
		date: "2026-08-12"
	}

	input {
		String path_exe = "gatk"

		File bam
		File bamIdx = sub(bam,"(m)$","i")
		String outputPath
		String subdir = ""
		String? name
		String suffix = ".leftAlign"

		File? intervals

		File refFasta
		File refFai = refFasta + ".fai"
		File refDict = sub(refFasta, "(.*).(fa|fasta)", "$1.dict")

		Boolean overlappingRule = false
		Int intervalsPadding = 0
		Boolean intersectionRule = false

		Boolean bamIndex = true
		Boolean bamMD5 = true

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

	String baseNameIntervals = if defined(intervals) then intervals else ""
	String baseIntervals = if defined(intervals) then sub(basename(baseNameIntervals),"([0-9]+)-scattered.interval_list","\.$1") else ""

	String baseName = if defined(name) then name else sub(basename(bam),"(\.[0-9]+)?\.(sam|bam|cram)$","")
	String ext = sub(basename(bam),"(.*)\.(sam|bam|cram)$","$2")
	String outputBamFile = "~{outputPath}/~{subdir}/~{baseName}~{suffix}~{baseIntervals}\.~{ext}"
	String outputBaiFile = sub(outputBamFile,"(m)$","i")

	command <<<

		if [[ ! -d $(dirname ~{outputBamFile}) ]]; then
			mkdir -p $(dirname ~{outputBamFile})
		fi

		~{path_exe} LeftAlignIndels \
			--input "~{bam}" \
			--reference "~{refFasta}" \
			--sequence-dictionary "~{refDict}" \
			~{default="" "--intervals " + intervals} \
			--interval-padding ~{intervalsPadding} \
			--interval-merging-rule ~{true="OVERLAPPING_ONLY" false="ALL" overlappingRule} \
			--interval-set-rule ~{true="INTERSECTION" false="UNION" intersectionRule} \
			~{true="--create-output-bam-index" false="" bamIndex} \
			~{true="--create-output-bam-md5" false="" bamMD5} \
			--output "~{outputBamFile}"

	>>>

	output {
		File outputBam = outputBamFile
		File outputBai = outputBaiFile
	}

	runtime {
		bind_opt: "~{outputPath}/~{subdir}" + "," + "~{bam}" + "," + "~{baseNameIntervals}" + "," + "~{refFasta}" + "~{default='' ',' + intervals}"
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
		subdir: {
			description: 'Subdirectory where to write output. [default: ""]',
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
		apptainer_img: {
			description: 'Sets the apptainer image you want to use [default: gatk4:4.6.2.0]',
			category: 'System'
		}
	}
}

task haplotypeCaller {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.1.0"
		date: "2026-08-14"
	}

	input {
		String path_exe = "gatk"

		Array[File] bam
		Array[File] bai
		String outputPath
		String subdir = ""
		String? name
		String subString = "\.(sam|bam|cram)$"
		String subStringReplace = ".haplotypeCaller.vcf"
		String subStringIntervals = "([0-9]+)-scattered.interval_list$"
		String subStringReplaceIntervals = ".$1"

		File refFasta
		File refFai = refFasta + ".fai"
		File refDict = sub(refFasta, "(.*).(fa|fasta)", "$1.dict")

		## Intervals
		File? intervals
		Int intervalsPadding = 0
		Boolean overlappingRule = false
		Boolean intersectionRule = false

		## Annotation
		File? dbsnp
		File? dbsnpIdx = if defined(dbsnp) then  dbsnp + ".tbi" else refFasta # Need to be fixed but it works... Using structs or objects should fixed that

		## Output
		Boolean createVCFIdx = true
		Boolean createVCFMD5 = true
		Boolean gvcf = false

		## Advanced
		Int maxMNPdistance = 0 
		Int maxReadsPerStart = 50
		Boolean disableSpanningEventGenotyping = true
		String smithAndWaterman = "FASTEST_AVAILABLE"

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

	String baseNameIntervals = if defined(intervals) then intervals else ""
	String getIntervalsBase = if defined(intervals) then sub(basename(baseNameIntervals),subStringIntervals,subStringReplaceIntervals) else ""

	String bn = if length(bam) == 1 then basename(bam[0]) else "MultiSample"
	String baseName = if defined(name) then name + getIntervalsBase + subStringReplace else sub(bn,subString,getIntervalsBase + subStringReplace)
	String outputFile = "~{outputPath}/~{subdir}/~{baseName}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} HaplotypeCaller \
			--input ~{sep=' --input  ' bam} \
			--reference ~{refFasta} \
			--sequence-dictionary ~{refDict} \
			~{true="--create-output-variant-index" false="" createVCFIdx} \
			~{true="--create-output-variant-md5" false="" createVCFMD5} \
			~{default="" "--intervals " + intervals} \
			--interval-padding ~{intervalsPadding} \
			~{default="" "--dbsnp " + dbsnp} \
			--interval-merging-rule ~{true="OVERLAPPING_ONLY" false="ALL" overlappingRule} \
			--interval-set-rule ~{true="INTERSECTION" false="UNION" intersectionRule} \
			~{true="--disable-spanning-event-genotyping" false="" disableSpanningEventGenotyping} \
			--max-mnp-distance ~{maxMNPdistance} \
			--max-reads-per-alignment-start ~{maxReadsPerStart} \
			--smith-waterman ~{smithAndWaterman} \
			--emit-ref-confidence ~{true="GVCF" false="NONE" gvcf} \
			--output ~{outputFile}
	>>>

	output {
		File outputVCF = outputFile
		File? outputVCFIdx = outputFile + ".idx"
		File? outputVCFMD5 = outputFile + ".md5"
	}

	runtime {
		bind_opt: "~{outputPath}/~{subdir}" + "," + "~{bam}" + "," + "~{baseNameIntervals}" + "," + "~{refFasta}" + "~{default='' ',' + intervals}"
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
			description: 'BAM file.',
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
		dbsnp: {
			description: 'Path to the file containing dbsnp (format: vcf)',
			category: 'Option: Annotation'
		}
		dbsnpIdx: {
			description: 'Path to the index of dbsnp file (format: tbi)',
			category: 'Option: Annotation'
		}
		createVCFIdx: {
			description: 'If true, create a VCF index when writing a coordinate-sorted VCF file. [Default: true]',
			category: 'Option: Output'
		}
		createVCFMD5: {
			description: 'If true, create a a MD5 digest any VCF file created. [Default: true]',
			category: 'Option: Output'
		}
		gvcf: {
			description: 'If true, Mode for emitting reference confidence scores, with condensed non-variant blocks, i.e. the GVCF format. [Default: false]',
			category: 'Option: Output'
		}
		maxMNPdistance: {
			description: 'Two or more phased substitutions separated by this distance or less are merged into MNPs. [default: 0]',
			category: 'Option: Advanced'
		}
		maxReadsPerStart: {
			description: 'Maximum number of reads to retain per alignment start position. Reads above this threshold will be downsampled. Set to 0 to disable. [default: 0]',
			category: 'Option: Advanced'
		}
		disableSpanningEventGenotyping: {
			description: 'If enabled this argument will disable inclusion of the "*" spanning event when genotyping events that overlap deletions [default: true]',
			category: 'Option: Advanced'
		}
		smithAndWaterman: {
			description: 'Which Smith-Waterman implementation to use, generally FASTEST_AVAILABLE is the right choice (possible values: FASTEST_AVAILABLE, AVX_ENABLED, JAVA) [default: FASTEST_AVAILABLE]',
			category: 'Option: Advanced'
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