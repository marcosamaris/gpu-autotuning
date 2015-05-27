#! /usr/bin/python2
import argparse
import os

argparser = argparse.ArgumentParser()
argparser.add_argument( "-f", "--file",
                        dest     = "filename",
                        type     = str,
                        required = True,
                        help     = "A file to run experiments in.")
argparser.add_argument( "-fargs", "--file-args",
                        dest     = "fargs",
                        type     = str,
                        nargs    = '*',
                        help     = "Program arguments.")
argparser.add_argument( "-ld", "--log-dir",
                        dest     = "logdir",
                        type     = str,
                        required = True,
                        help     = "Directory to save this tuning run.")
argparser.add_argument( "-lc", "--log-cmd",
                        dest     = "logcmd",
                        type     = str,
                        required = True,
                        help     = "File to save best configuration to.")
argparser.add_argument( "-time", "--run-time",
                        dest     = "time",
                        type     = str,
                        required = True,
                        help     = "Time to tune the program.")
argparser.add_argument( "-th", "--threads",
                        dest     = "parallelism",
                        type     = str,
                        required = True,
                        help     = "Number of threads to run the tuning program.")
argparser.add_argument( "-r", "--tuning-runs",
                        dest     = "runs",
                        type     = int,
                        required = True,
                        help     = "Number of tuning runs to perform.")
argparser.add_argument( "-br", "--benchmark-runs",
                        dest     = "benchmark",
                        type     = str,
                        required = True,
                        help     = "Number of times to run the final configuration.")
argparser.add_argument( "-tech", "--choose-technique",
                        dest     = "technique",
                        type     = str,
                        default  = "",
                        required = False,
                        help     = "Force OpenTuner to use an ensemble or specific technique.")
argparser.add_argument( "-s", "--seed",
                        dest     = "seed",
                        type     = str,
                        default  = "",
                        required = False,
                        help     = "A seed configuration, to start the search in.")

if __name__ == '__main__':
    args =  argparser.parse_args()
    cmd  = "python2 nvcc_flags_tuner.py --no-dups"

    for i in range(args.runs):
        run_id = "/run_" + str(i)
        log_path = args.logdir + run_id
        os.system("mkdir " + log_path)

        cmd += " --stop-after="         + args.time
        cmd += " --file="               + args.filename
        cmd += " --file-args="          + "\"" + " ".join(args.fargs) + "\""
        cmd += " --log-dir="            + args.logdir + run_id + "/"
        cmd += " --log-cmd="            + args.logcmd
        cmd += " --parallelism="        + args.parallelism
        cmd += " --results-log-detail=" + args.logdir + run_id + "/logall.txt"
        cmd += " --results-log="        + args.logdir + run_id + "/logbest.txt"

        if args.technique != "":
            cmd += " --technique=" + args.technique
        if args.seed != "":
            cmd += " --seed-configuration=" + args.seed

        os.system(cmd)

    os.system("rm -r opentuner.log opentuner.db")
