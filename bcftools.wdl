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
		date: "2026-09-07"
	}

	input {
		String path_exe = "bcftools"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
		String apptainer_img = "bcftools:1.23.1"
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	command <<<
		~{path_exe} --version | head -1
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
			description: 'Path used as executable [default: "bcftools"]',
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
			description: 'Sets the apptainer image you want to use [default: bcftools:1.23.1]',
			category: 'System'
		}
	}
}

task norm {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.1.0"
		date: "2026-09-07"
	}

	input {
		String path_exe = "bcftools"

		File vcf
		String outputPath
		String subdir = ""
		String? name
		String subString = "\.(vcf|bcf)(\.gz)?$"
		String subStringReplace = ""
		String suffix = ".norm"

		File refFasta
		File refFai = refFasta + ".fai"

		String? checkRef

		Boolean removeDuplicates = false
		String? rmDupType

		Boolean splitMA = false
		String multiallelicType = "both"

		Boolean version = true

		Boolean normalize = true

		String? regions
		File? regionsFile

		String? targets
		File? targetsFile

		Boolean strictFilter = false
		String outputType = "z"

		Int siteWin = 1000

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
		String apptainer_img = "bcftools:1.23.1"
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	Map[String,String] extType = {"v" : ".vcf", "u" : ".bcf", "z" : ".vcf.gz", "b" : ".bcf.gz"}
	Map[String,String] idxType = {"v" : "", "u" : "csi", "z" : "tbi", "b" : "csi"}
	Map[String,Boolean] idx = {"v" : false, "u" : true, "z" : true, "b" : true}

	String ext = extType[outputType]
	String idxFmt = idxType[outputType]
	Boolean index = idx[outputType]

	String baseName = if defined(name) then name else sub(basename(vcf),subString,subStringReplace)
	String outputFile = "~{outputPath}/~{subdir}/~{baseName}~{suffix}~{ext}"

	String multiallelics = if splitMA then "-~{multiallelicType}" else "+~{multiallelicType}"

	command <<<

		if [[ ! -f ~{outputFile} ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} norm \
			~{default="" "--check-ref " + checkRef} \
			~{true="--remove-duplicates" false="" removeDuplicates} \
			~{default="" "--rm-dup " + rmDupType} \
			--fasta-ref ~{refFasta} \
			--multiallelics ~{multiallelics} \
			~{true="" false="--no-version" version} \
			~{true="" false="--do-not-normalize" normalize} \
			~{default="" "--regions " + regions} \
			~{default="" "--regions-file " + regionsFile} \
			~{default="" "--targets " + targets} \
			~{default="" "--targets-file " + targetsFile} \
			~{true="--strict-filter" false="" strictFilter} \
			--output-type ~{outputType} \
			--output ~{outputFile} \
			--threads ~{threads - 1} \
			--site-win ~{siteWin} \
			~{true="-W" false="" index}~{idxFmt} \
			~{vcf}

	>>>

	output {
		File outputvcf = outputFile
		File? outputidx = outputFile + "." + idxFmt
	}

	runtime {
		bind_opt: "~{outputPath}/~{subdir}" + "," + "~{refFasta}" + "," + "~{vcf}" + "~{default='' ',' + regionsFile}"  + "~{default='' ',' + targetsFile}" 
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
		docker: "~{apptainer_img}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "bcftools"]',
			category: 'System'
		}
		vcf: {
			description: "VCF/BCF file to left-align and normalize indels (extension: '.vcf.gz|.bcf')",
			category: 'Required'
		}
		outputPath: {
			description: 'Path where was generated output',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(in),subString,"")].',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Extension to remove from the input file [default: "\.(vcf|bcf)(\.gz)?$"]',
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
		refFasta: {
			description: 'Reference used to merge in gvcf mode',
			category: 'Required'
		}
		refFai: {
			description: 'Path to the reference file index (format: fai)',
			category: 'Required'
		}
		checkRef: {
			description: 'Check REF alleles and exit (e), warn (w), exclude (x), or set (s) bad sites [default: e]',
			category: 'Tool option'
		}
		removeDuplicates: {
			description: 'Remove duplicate lines of the same type.',
			category: 'Tool option'
		}
		rmDupType: {
			description: 'Remove duplicate snps|indels|both|all|none (implies removeDuplicates)',
			category: 'Tool option'
		}
		splitMA: {
			description: "Split (true) or join (false) multiallelics sites [default= false]",
			category: 'Tool option'
		}
		multiallelicType: {
			description: "Type of Multiallelics to treat for split/join (type: snps|indels|both|any) [default: both]",
			category: 'Tool option'
		}
		version: {
			description: 'Append version and command line to the header [default: true]',
			category: 'Tool option'
		}
		normalize: {
			description: 'Normalize indels (with -m or -c s) [default: true]',
			category: 'Tool option'
		}
		outputType: {
			description: '"b" compressed BCF; "u" uncompressed BCF; "z" compressed VCF; "v" uncompressed VCF [default: "z"]',
			category: 'Tool option'
		}
		regions: {
			description: "Restrict to comma-separated list of regions",
			category: 'Tool option'
		}
		regionsFile: {
			description: "Restrict to regions listed in a file",
			category: 'Tool option'
		}
		targets: {
			description: "Similar to 'regions' but streams rather than index-jumps",
			category: 'Tool option'
		}
		targetsFile: {
			description: "Similar to 'regionsFile' but streams rather than index-jumps",
			category: 'Tool option'
		}
		strictFilter: {
			description: "When merging (-m+), merged site is PASS only if all sites being merged PASS [default: false]",
			category: 'Tool option'
		}
		siteWin: {
			description: "Buffer for sorting lines which changed position during realignment [default: 1000]",
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
			description: 'Sets the apptainer image you want to use [default: bcftools:1.23.1]',
			category: 'System'
		}
	}
}
